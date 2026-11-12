from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.auth.emailer import EmailSender
from app.auth.providers import TokenVerifier
from app.config import Settings
from app.database import get_db
from app.errors import AppError
from app.security import decode_access_token
from app.users.models import User

_bearer = HTTPBearer(auto_error=False)


def get_app_settings(request: Request) -> Settings:
    return request.app.state.settings  # type: ignore[no-any-return]


def get_email_sender(request: Request) -> EmailSender:
    return request.app.state.email_sender  # type: ignore[no-any-return]


def get_verifier(request: Request, provider: str) -> TokenVerifier:
    return request.app.state.verifiers[provider]  # type: ignore[no-any-return]


def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    settings: Settings = Depends(get_app_settings),
    db: Session = Depends(get_db),
) -> User:
    unauthorized = AppError("unauthorized", "Connectez-vous pour continuer.", 401)
    if credentials is None:
        raise unauthorized
    user_id = decode_access_token(credentials.credentials, settings.jwt_secret)
    user = db.get(User, user_id) if user_id else None
    if user is None:
        raise unauthorized
    return user
