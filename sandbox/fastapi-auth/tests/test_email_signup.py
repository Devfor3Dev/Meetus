from sqlalchemy.orm import Session

from app.config import Settings
from app.users.models import User
from tests.conftest import (
    EMAIL,
    PASSWORD,
    RecordingSender,
    bearer,
    error_code,
    login,
    register,
    verified_account,
)


def test_unknown_email_does_not_exist(client) -> None:
    response = client.post("/auth/check-email", json={"email": EMAIL})
    assert response.json() == {"exists": False, "is_verified": False}


def test_check_email_follows_the_account_state(client, sender: RecordingSender) -> None:
    register(client)
    assert client.post("/auth/check-email", json={"email": EMAIL}).json() == {
        "exists": True,
        "is_verified": False,
    }

    client.get("/auth/verify", params={"token": sender.last_token()})
    assert client.post("/auth/check-email", json={"email": EMAIL}).json() == {
        "exists": True,
        "is_verified": True,
    }


def test_register_sends_one_link_and_stores_no_clear_password(
    client, sender: RecordingSender
) -> None:
    response = register(client, "  Awa@EXEMPLE.tg ")

    assert response.status_code == 202
    assert len(sender.sent) == 1
    to, first_name, link = sender.sent[0]
    assert to == EMAIL
    assert first_name == "Awa"
    assert link.startswith("http://api.test/auth/verify?token=")
    with Session(client.app.state.engine) as db:
        user = db.query(User).one()
        assert user.is_verified is False
        assert user.password_hash is not None
        assert user.password_hash.startswith("$argon2")
        assert PASSWORD not in user.password_hash


def test_verification_link_confirms_and_points_to_the_app(client, sender: RecordingSender) -> None:
    register(client)

    page = client.get("/auth/verify", params={"token": sender.last_token()})

    assert page.status_code == 200
    assert "loveline://verified" in page.text
    assert page.headers["content-type"].startswith("text/html")


def test_verification_link_works_once_only(client, sender: RecordingSender) -> None:
    register(client)
    token = sender.last_token()
    client.get("/auth/verify", params={"token": token})

    again = client.get("/auth/verify", params={"token": token})

    assert again.status_code == 400
    assert "loveline://" not in again.text


def test_garbage_verification_token_is_refused(client) -> None:
    assert client.get("/auth/verify", params={"token": "nimporte-quoi"}).status_code == 400


def test_login_is_refused_until_the_email_is_verified(client, sender: RecordingSender) -> None:
    register(client)

    refused = login(client)
    assert refused.status_code == 403
    assert error_code(refused) == "email_not_verified"

    client.get("/auth/verify", params={"token": sender.last_token()})
    assert login(client).status_code == 200


def test_login_opens_a_session_with_an_http_only_cookie(client, sender: RecordingSender) -> None:
    verified_account(client, sender)

    response = login(client)

    assert "refresh_token" not in response.json()
    cookie = response.headers["set-cookie"].lower()
    assert "httponly" in cookie
    assert "samesite=strict" in cookie
    assert "path=/auth" in cookie
    me = client.get("/auth/me", headers=bearer(response)).json()
    assert (me["first_name"], me["last_name"]) == ("Awa", "Koffi")
    assert me["needs_identity"] is False
    assert me["is_verified"] is True


def test_wrong_password_and_unknown_email_look_the_same(client, sender: RecordingSender) -> None:
    verified_account(client, sender)

    wrong = login(client, password="faux-faux-faux")
    unknown = login(client, email="personne@exemple.tg")

    assert wrong.status_code == unknown.status_code == 401
    assert error_code(wrong) == error_code(unknown) == "invalid_credentials"


def test_five_failures_lock_the_account_even_for_the_right_password(
    client, sender: RecordingSender
) -> None:
    verified_account(client, sender)
    for _ in range(5):
        login(client, password="faux-faux-faux")

    locked = login(client)

    assert locked.status_code == 429
    assert error_code(locked) == "too_many_attempts"


def test_registering_a_verified_email_is_refused(client, sender: RecordingSender) -> None:
    verified_account(client, sender)

    response = register(client)

    assert response.status_code == 409
    assert error_code(response) == "email_already_registered"


def test_an_abandoned_signup_can_be_resumed(client, sender: RecordingSender) -> None:
    register(client)
    register(client, first_name="Awa-Marie", password="un-autre-mot-de-passe")

    assert len(sender.sent) == 2
    client.get("/auth/verify", params={"token": sender.last_token()})
    assert login(client, password="un-autre-mot-de-passe").status_code == 200
    assert login(client, password=PASSWORD).status_code == 401


def test_registration_rejects_weak_passwords_and_bad_names(client) -> None:
    short = register(client, password="court")
    assert short.status_code == 422
    assert error_code(short) == "weak_password"

    assert error_code(register(client, first_name="Awa2")) == "validation_error"
    assert error_code(register(client, last_name="<b>")) == "validation_error"
    assert error_code(register(client, email="pas-un-mail")) == "validation_error"


def test_registration_keeps_accents_and_apostrophes(client, sender: RecordingSender) -> None:
    register(client, first_name="Éloïse", last_name="N'Dri-Koffi")
    client.get("/auth/verify", params={"token": sender.last_token()})

    me = client.get("/auth/me", headers=bearer(login(client))).json()

    assert (me["first_name"], me["last_name"]) == ("Éloïse", "N'Dri-Koffi")


def test_domain_allow_list_applies_to_check_and_register(make_client, settings: Settings) -> None:
    client = make_client(settings.model_copy(update={"allowed_email_domains": "univ.tg"}))

    assert client.post("/auth/check-email", json={"email": "pirate@gmail.com"}).status_code == 403
    refused = register(client, "pirate@gmail.com")
    assert error_code(refused) == "email_domain_not_allowed"
    assert register(client, "etu@etu.univ.tg").status_code == 202


def test_resend_sends_a_new_link_but_not_twice_in_a_row(client, sender: RecordingSender) -> None:
    register(client)

    first = client.post("/auth/resend-verification", json={"email": EMAIL})
    second = client.post("/auth/resend-verification", json={"email": EMAIL})

    assert first.status_code == second.status_code == 202
    assert len(sender.sent) == 1


def test_resend_reveals_nothing_about_unknown_or_verified_accounts(
    client, sender: RecordingSender
) -> None:
    verified_account(client, sender)
    sender.sent.clear()

    unknown = client.post("/auth/resend-verification", json={"email": "personne@exemple.tg"})
    verified = client.post("/auth/resend-verification", json={"email": EMAIL})

    assert unknown.json() == verified.json() == {"status": "verification_sent"}
    assert sender.sent == []
