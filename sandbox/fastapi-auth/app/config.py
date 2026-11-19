"""Configuration de l'API d'essai, lue dans l'environnement ou dans un fichier .env."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "sqlite:///./dev.db"

    # Clé de signature des jetons d'accès. Obligatoire :
    jwt_secret: str

    # Adresse publique de l'API, utilisée pour fabriquer le lien de confirmation envoyé par
    # e-mail. Depuis un téléphone, c'est l'adresse de votre machine ou d'un tunnel, pas localhost.
    public_base_url: str = (
        "https://ankle-issuing-circular.ngrok-free.dev"  # "http://localhost:8000"
    )

    # Identifiant client OAuth de type Web (Google Cloud), celui que le téléphone reçoit
    # comme serverClientId.
    google_client_id: str = ""

    # Application Facebook : l'identifiant et la clé secrète servent à vérifier les jetons.
    facebook_app_id: str = ""
    facebook_app_secret: str = ""

    access_token_ttl_seconds: int = 15 * 60
    refresh_token_ttl_seconds: int = 30 * 24 * 3600
    verification_token_ttl_seconds: int = 24 * 3600
    resend_cooldown_seconds: int = 60

    max_failed_logins: int = 5
    login_lock_seconds: int = 10 * 60

    # Mettre false uniquement en développement, où l'émulateur parle en http.
    cookie_secure: bool = True

    # Domaines autorisés pour l'inscription, séparés par des virgules. Vide signifie tous.
    allowed_email_domains: str = ""

    @property
    def email_domains(self) -> list[str]:
        return [d.strip().lower() for d in self.allowed_email_domains.split(",") if d.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
