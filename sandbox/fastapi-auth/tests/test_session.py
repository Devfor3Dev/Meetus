import jwt
from sqlalchemy import update
from sqlalchemy.orm import Session

from app.auth.models import RefreshToken
from app.security import encode_access_token, utcnow
from tests.conftest import GOOGLE_TOKEN, bearer, error_code


def google_login(client):
    return client.post("/auth/google", json={"id_token": GOOGLE_TOKEN})


def refresh(client):
    return client.post("/auth/refresh")


def test_refresh_rotates_the_cookie_and_returns_a_new_access_token(client) -> None:
    first_cookie = google_login(client).cookies["refresh_token"]

    response = refresh(client)

    assert response.status_code == 200
    assert response.json()["access_token"]
    assert client.cookies["refresh_token"] != first_cookie


def test_refresh_without_cookie_is_refused(client) -> None:
    response = refresh(client)
    assert response.status_code == 401
    assert error_code(response) == "invalid_refresh_token"


def test_reusing_a_rotated_token_revokes_the_whole_family(client) -> None:
    stolen = google_login(client).cookies["refresh_token"]
    assert refresh(client).status_code == 200

    client.cookies.set("refresh_token", stolen, path="/auth")
    assert refresh(client).status_code == 401

    # Le jeton légitime, issu de la rotation, est lui aussi devenu inutilisable.
    assert refresh(client).status_code == 401


def test_expired_refresh_token_is_refused(client) -> None:
    google_login(client)
    with Session(client.app.state.engine) as db:
        db.execute(update(RefreshToken).values(expires_at=utcnow().replace(year=2020)))
        db.commit()
    assert refresh(client).status_code == 401


def test_only_fingerprints_are_stored(client) -> None:
    raw = google_login(client).cookies["refresh_token"]
    with Session(client.app.state.engine) as db:
        hashes = [row.token_hash for row in db.query(RefreshToken)]
    assert raw not in hashes
    assert all(len(h) == 64 for h in hashes)


def test_logout_revokes_the_session_and_clears_the_cookie(client) -> None:
    google_login(client)

    assert client.post("/auth/logout").status_code == 204
    assert refresh(client).status_code == 401


def test_logout_without_session_is_harmless(client) -> None:
    assert client.post("/auth/logout").status_code == 204


def test_profile_requires_a_token(client) -> None:
    response = client.get("/auth/me")
    assert response.status_code == 401
    assert error_code(response) == "unauthorized"


def test_garbage_foreign_and_expired_tokens_are_refused(client, settings) -> None:
    assert (
        client.get("/auth/me", headers={"Authorization": "Bearer abc.def.ghi"}).status_code == 401
    )
    forged = jwt.encode(
        {"sub": "x", "typ": "access", "iat": 1, "exp": 4102444800}, "autre-cle" * 5, "HS256"
    )
    assert client.get("/auth/me", headers={"Authorization": f"Bearer {forged}"}).status_code == 401

    user_id = google_login(client).json()["user"]["id"]
    expired = encode_access_token(user_id, settings.jwt_secret, -60)
    assert client.get("/auth/me", headers={"Authorization": f"Bearer {expired}"}).status_code == 401


def test_valid_token_unlocks_the_profile(client) -> None:
    assert client.get("/auth/me", headers=bearer(google_login(client))).status_code == 200


def test_health(client) -> None:
    assert client.get("/health/live").json() == {"status": "ok"}
    assert client.get("/health/ready").json() == {"status": "ok"}
