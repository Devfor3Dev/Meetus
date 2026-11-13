import pytest
from fastapi.testclient import TestClient

from app.auth import models as _auth_models  # noqa: F401
from app.auth.providers import InvalidProviderToken, ProviderIdentity
from app.config import Settings
from app.database import Base
from app.main import create_app
from app.users import models as _user_models  # noqa: F401

PASSWORD = "un-bon-mot-de-passe"
EMAIL = "awa@exemple.tg"


class FakeVerifier:
    """Remplace Google ou Facebook : chaque jeton de test correspond à une identité connue."""

    def __init__(self, provider: str) -> None:
        self.provider = provider
        self.identities: dict[str, ProviderIdentity] = {}

    def add(self, token: str, subject: str, email: str | None, trusted: bool = True) -> str:
        self.identities[token] = ProviderIdentity(
            provider=self.provider, subject=subject, email=email, email_trusted=trusted
        )
        return token

    def verify(self, token: str) -> ProviderIdentity:
        if token not in self.identities:
            raise InvalidProviderToken("jeton inconnu")
        return self.identities[token]


class RecordingSender:
    def __init__(self) -> None:
        self.sent: list[tuple[str, str, str]] = []

    def send_verification(self, to: str, first_name: str, link: str) -> None:
        self.sent.append((to, first_name, link))

    def last_token(self) -> str:
        return self.sent[-1][2].split("token=")[1]


@pytest.fixture
def settings() -> Settings:
    return Settings(
        database_url="sqlite://",
        jwt_secret="secret-de-test-secret-de-test-123456",
        public_base_url="http://api.test",
        cookie_secure=False,
    )


@pytest.fixture
def sender() -> RecordingSender:
    return RecordingSender()


@pytest.fixture
def google() -> FakeVerifier:
    fake = FakeVerifier("google")
    fake.add("g" * 30 + "awa", "g-awa", EMAIL)
    return fake


@pytest.fixture
def facebook() -> FakeVerifier:
    fake = FakeVerifier("facebook")
    fake.add("f" * 30 + "awa", "f-awa", EMAIL, trusted=False)
    return fake


@pytest.fixture
def make_client(sender: RecordingSender, google: FakeVerifier, facebook: FakeVerifier):
    def build(settings: Settings, verifiers: dict | None = None) -> TestClient:
        app = create_app(
            settings,
            verifiers if verifiers is not None else {"google": google, "facebook": facebook},
            sender,
        )
        Base.metadata.create_all(app.state.engine)
        return TestClient(app)

    return build


@pytest.fixture
def client(make_client, settings: Settings) -> TestClient:
    return make_client(settings)


GOOGLE_TOKEN = "g" * 30 + "awa"
FACEBOOK_TOKEN = "f" * 30 + "awa"


def register(client: TestClient, email: str = EMAIL, **overrides):
    body = {
        "email": email,
        "first_name": "Awa",
        "last_name": "Koffi",
        "password": PASSWORD,
    } | overrides
    return client.post("/auth/register", json=body)


def login(client: TestClient, email: str = EMAIL, password: str = PASSWORD):
    return client.post("/auth/login", json={"email": email, "password": password})


def verified_account(client: TestClient, sender: RecordingSender, email: str = EMAIL) -> None:
    assert register(client, email).status_code == 202
    assert client.get("/auth/verify", params={"token": sender.last_token()}).status_code == 200


def bearer(response) -> dict[str, str]:
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def error_code(response) -> str:
    return response.json()["error"]["code"]
