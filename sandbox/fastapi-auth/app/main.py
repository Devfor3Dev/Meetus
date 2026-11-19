"""API d'essai de Loveline ."""

from fastapi import FastAPI
from sqlalchemy.orm import sessionmaker

from app import health
from app.auth import router as auth_router
from app.auth.emailer import ConsoleEmailSender, EmailSender
from app.auth.providers import FacebookVerifier, GoogleVerifier, TokenVerifier
from app.config import Settings, get_settings
from app.database import make_engine
from app.errors import install_error_handlers


def create_app(
    settings: Settings | None = None,
    verifiers: dict[str, TokenVerifier] | None = None,
    email_sender: EmailSender | None = None,
) -> FastAPI:
    settings = settings or get_settings()
    app = FastAPI(title="Loveline API d'essai", version="0.2.0", docs_url=None, redoc_url=None)

    engine = make_engine(settings.database_url)
    app.state.settings = settings
    app.state.engine = engine
    app.state.session_factory = sessionmaker(engine, expire_on_commit=False)
    app.state.email_sender = email_sender or ConsoleEmailSender()
    app.state.verifiers = (
        verifiers
        if verifiers is not None
        else {
            "google": GoogleVerifier(settings.google_client_id),
            "facebook": FacebookVerifier(settings.facebook_app_id, settings.facebook_app_secret),
        }
    )

    install_error_handlers(app)
    app.include_router(health.router)
    app.include_router(auth_router.router)
    return app


def app_factory() -> FastAPI:
    """Utilisé par uvicorn avec l'option --factory."""
    return create_app()
