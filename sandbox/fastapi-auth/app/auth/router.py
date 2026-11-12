from fastapi import APIRouter, Cookie, Depends, Request, Response
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.auth import service
from app.auth.dependencies import current_user, get_app_settings, get_email_sender
from app.auth.emailer import EmailSender
from app.auth.schemas import (
    AccessOut,
    AuthOut,
    CheckEmailIn,
    CheckEmailOut,
    FacebookLoginIn,
    GoogleLoginIn,
    IdentityIn,
    LoginIn,
    RegisterIn,
    ResendIn,
)
from app.config import Settings
from app.database import get_db
from app.errors import AppError
from app.users.models import User
from app.users.schemas import UserOut

router = APIRouter(prefix="/auth", tags=["auth"])

COOKIE_NAME = "refresh_token"
# Le chemin couvre /auth/refresh et /auth/logout
COOKIE_PATH = "/auth"
APP_SCHEME = "loveline"


def _set_refresh_cookie(response: Response, settings: Settings, raw: str) -> None:
    response.set_cookie(
        COOKIE_NAME,
        raw,
        max_age=settings.refresh_token_ttl_seconds,
        httponly=True,
        secure=settings.cookie_secure,
        samesite="strict",
        path=COOKIE_PATH,
    )


@router.post("/check-email", response_model=CheckEmailOut)
def check_email(
    payload: CheckEmailIn,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
) -> CheckEmailOut:
    exists, verified = service.email_status(db, settings, payload.email)
    return CheckEmailOut(exists=exists, is_verified=verified)


@router.post("/register", status_code=202)
def register(
    payload: RegisterIn,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
    sender: EmailSender = Depends(get_email_sender),
) -> dict[str, str]:
    service.register(
        db,
        settings,
        sender,
        email=payload.email,
        first_name=payload.first_name,
        last_name=payload.last_name,
        password=payload.password,
    )
    return {"status": "verification_sent"}


@router.post("/resend-verification", status_code=202)
def resend_verification(
    payload: ResendIn,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
    sender: EmailSender = Depends(get_email_sender),
) -> dict[str, str]:
    service.resend_verification(db, settings, sender, payload.email)
    return {"status": "verification_sent"}


_PAGE = """<!doctype html>
<html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Loveline</title>{refresh}
<style>body{{font-family:system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1.5rem}}
a.button{{display:inline-block;margin-top:1rem;padding:.9rem 1.4rem;
border-radius:2rem;background:#c2184a;color:#fff;text-decoration:none}}</style>
</head><body><h1>{title}</h1><p>{body}</p>{button}</body></html>"""


@router.get("/verify", response_class=HTMLResponse)
def verify(token: str, db: Session = Depends(get_db)) -> HTMLResponse:
    """Page du lien reçu par e-mail : confirme l'adresse puis renvoie à l'application."""
    if service.verify_email(db, token):
        target = f"{APP_SCHEME}://verified"
        page = _PAGE.format(
            refresh=f'<meta http-equiv="refresh" content="0;url={target}">',
            title="Adresse confirmée",
            body="Vous pouvez retourner dans l'application Loveline.",
            button=f'<a class="button" href="{target}">Ouvrir Loveline</a>',
        )
        return HTMLResponse(page)
    page = _PAGE.format(
        refresh="",
        title="Lien invalide",
        body="Ce lien a expiré ou a déjà servi. Demandez un nouvel e-mail depuis l'application.",
        button="",
    )
    return HTMLResponse(page, status_code=400)


@router.post("/login", response_model=AccessOut)
def login(
    payload: LoginIn,
    response: Response,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
) -> AccessOut:
    session = service.login(db, settings, email=payload.email, password=payload.password)
    _set_refresh_cookie(response, settings, session.refresh_token)
    return AccessOut(access_token=session.access_token, expires_in=session.expires_in)


def _provider_login(
    provider: str,
    token: str,
    request: Request,
    response: Response,
    db: Session,
    settings: Settings,
) -> AuthOut:
    verifier = request.app.state.verifiers.get(provider)
    if verifier is None:
        raise AppError("provider_disabled", "Cette méthode de connexion n'est pas disponible.", 404)
    user, session = service.sign_in_with_provider(db, settings, verifier, token)
    _set_refresh_cookie(response, settings, session.refresh_token)
    return AuthOut(
        access_token=session.access_token,
        expires_in=session.expires_in,
        user=UserOut.model_validate(user),
    )


@router.post("/google", response_model=AuthOut)
def google_login(
    payload: GoogleLoginIn,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
) -> AuthOut:
    return _provider_login("google", payload.id_token, request, response, db, settings)


@router.post("/facebook", response_model=AuthOut)
def facebook_login(
    payload: FacebookLoginIn,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
) -> AuthOut:
    return _provider_login("facebook", payload.access_token, request, response, db, settings)


@router.post("/refresh", response_model=AccessOut)
def refresh(
    response: Response,
    refresh_token: str | None = Cookie(default=None),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_app_settings),
) -> AccessOut:
    if not refresh_token:
        raise AppError("invalid_refresh_token", "Votre session a expiré.", 401)
    session = service.rotate_refresh_token(db, settings, refresh_token)
    _set_refresh_cookie(response, settings, session.refresh_token)
    return AccessOut(access_token=session.access_token, expires_in=session.expires_in)


@router.post("/logout", status_code=204)
def logout(
    refresh_token: str | None = Cookie(default=None),
    db: Session = Depends(get_db),
) -> Response:
    if refresh_token:
        service.revoke_session(db, refresh_token)
    response = Response(status_code=204)
    response.delete_cookie(COOKIE_NAME, path=COOKIE_PATH)
    return response


@router.get("/me", response_model=UserOut)
def read_me(user: User = Depends(current_user)) -> User:
    return user


@router.patch("/me", response_model=UserOut)
def update_identity(
    payload: IdentityIn,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> User:
    user.first_name = payload.first_name
    user.last_name = payload.last_name
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
