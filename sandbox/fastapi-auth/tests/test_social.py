from sqlalchemy.orm import Session

from app.config import Settings
from app.users.models import User
from tests.conftest import (
    EMAIL,
    FACEBOOK_TOKEN,
    GOOGLE_TOKEN,
    PASSWORD,
    FakeVerifier,
    RecordingSender,
    bearer,
    error_code,
    login,
    verified_account,
)


def google_login(client, token: str = GOOGLE_TOKEN):
    return client.post("/auth/google", json={"id_token": token})


def facebook_login(client, token: str = FACEBOOK_TOKEN):
    return client.post("/auth/facebook", json={"access_token": token})


def test_first_google_login_creates_a_verified_account_needing_identity(client) -> None:
    response = google_login(client)

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "Bearer"
    assert body["user"]["email"] == EMAIL
    assert body["user"]["is_verified"] is True
    assert body["user"]["needs_identity"] is True


def test_refresh_token_travels_only_in_an_http_only_cookie(client) -> None:
    response = google_login(client)

    assert "refresh_token" not in response.json()
    cookie = response.headers["set-cookie"].lower()
    assert "httponly" in cookie
    assert "samesite=strict" in cookie
    assert "path=/auth" in cookie


def test_cookie_is_secure_by_default(make_client, settings: Settings) -> None:
    client = make_client(settings.model_copy(update={"cookie_secure": True}))
    assert "secure" in google_login(client).headers["set-cookie"].lower()


def test_second_login_returns_the_same_account(client) -> None:
    assert google_login(client).json()["user"]["id"] == google_login(client).json()["user"]["id"]


def test_unknown_provider_token_is_refused(client) -> None:
    response = google_login(client, "x" * 40)
    assert response.status_code == 401
    assert error_code(response) == "invalid_provider_token"


def test_google_links_to_an_existing_verified_account(client, sender: RecordingSender) -> None:
    verified_account(client, sender)
    existing = login(client)
    me_id = client.get("/auth/me", headers=bearer(existing)).json()["id"]

    response = google_login(client)

    assert response.json()["user"]["id"] == me_id
    assert login(client).status_code == 200


def test_google_confirms_an_unverified_account_it_links_to(client, sender: RecordingSender) -> None:
    client.post(
        "/auth/register",
        json={"email": EMAIL, "first_name": "Awa", "last_name": "Koffi", "password": PASSWORD},
    )

    google_login(client)

    with Session(client.app.state.engine) as db:
        assert db.query(User).one().is_verified is True


def test_facebook_never_links_to_an_existing_account(client, sender: RecordingSender) -> None:
    verified_account(client, sender)

    response = facebook_login(client)

    assert response.status_code == 409
    assert error_code(response) == "account_exists_other_method"


def test_facebook_creates_a_new_account(client, facebook: FakeVerifier) -> None:
    token = facebook.add("n" * 30, "f-new", "nouveau@exemple.tg", trusted=False)

    response = facebook_login(client, token)

    assert response.status_code == 200
    assert response.json()["user"]["needs_identity"] is True


def test_provider_without_email_is_refused(client, facebook: FakeVerifier) -> None:
    token = facebook.add("m" * 30, "f-noemail", None, trusted=False)

    response = facebook_login(client, token)

    assert response.status_code == 422
    assert error_code(response) == "provider_email_missing"


def test_disabled_provider_returns_not_found(make_client, settings: Settings) -> None:
    client = make_client(settings, verifiers={})
    assert facebook_login(client).status_code == 404


def test_domain_allow_list_applies_to_provider_emails(
    make_client, settings: Settings, google: FakeVerifier
) -> None:
    client = make_client(settings.model_copy(update={"allowed_email_domains": "univ.tg"}))
    outsider = google.add("o" * 30, "g-o", "pirate@gmail.com")

    refused = google_login(client, outsider)

    assert refused.status_code == 403
    assert error_code(refused) == "email_domain_not_allowed"


def test_identity_is_saved_and_clears_the_flag(client) -> None:
    headers = bearer(google_login(client))

    response = client.patch(
        "/auth/me", headers=headers, json={"first_name": "  Awa  ", "last_name": "N'Dri-Koffi"}
    )

    assert response.status_code == 200
    assert response.json()["first_name"] == "Awa"
    assert response.json()["needs_identity"] is False
    assert client.get("/auth/me", headers=headers).json()["needs_identity"] is False


def test_identity_rejects_invalid_names(client) -> None:
    headers = bearer(google_login(client))
    for bad in ("", "   ", "Awa2", "<b>", "A" * 51, "-Awa"):
        response = client.patch(
            "/auth/me", headers=headers, json={"first_name": bad, "last_name": "Koffi"}
        )
        assert response.status_code == 422, bad
