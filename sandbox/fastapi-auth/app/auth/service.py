"""Inscription par e-mail, connexion, Google et Facebook, sessions.

Chaque connexion crée une famille de jetons de renouvellement. Un jeton ne sert
au cas cotraire on va révoquer toute la famille
"""

import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import timedelta

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth.emailer import EmailSender
from app.auth.models import EmailVerificationToken, RefreshToken, SocialIdentity
from app.auth.passwords import hash_password, verify_password
from app.auth.providers import InvalidProviderToken, ProviderIdentity, TokenVerifier
from app.config import Settings
from app.errors import AppError
from app.security import (
    as_utc,
    encode_access_token,
    fingerprint,
    new_refresh_token,
    utcnow,
)
from app.users.models import User
from app.users.schemas import clean_name

MIN_PASSWORD = 8
MAX_PASSWORD = 128


@dataclass(frozen=True)
class IssuedSession:
    access_token: str
    refresh_token: str
    expires_in: int


def normalize_email(raw: str) -> str:
    return raw.strip().lower()


def _check_email(email: str, settings: Settings) -> None:
    local, _, domain = email.rpartition("@")
    if not local or "." not in domain or " " in email:
        raise AppError("validation_error", "Adresse e-mail invalide.", 422)
    domains = settings.email_domains
    if domains and not any(domain == d or domain.endswith(f".{d}") for d in domains):
        raise AppError(
            "email_domain_not_allowed", "Utilisez l'adresse de votre établissement.", 403
        )


def _find_user(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(User.email == email))


# Sessions


def issue_session(
    db: Session, settings: Settings, user: User, family_id: str | None = None
) -> IssuedSession:
    raw = new_refresh_token()
    db.add(
        RefreshToken(
            user_id=user.id,
            family_id=family_id or str(uuid.uuid4()),
            token_hash=fingerprint(raw),
            expires_at=utcnow() + timedelta(seconds=settings.refresh_token_ttl_seconds),
        )
    )
    db.commit()
    return IssuedSession(
        access_token=encode_access_token(
            user.id, settings.jwt_secret, settings.access_token_ttl_seconds
        ),
        refresh_token=raw,
        expires_in=settings.access_token_ttl_seconds,
    )


def rotate_refresh_token(db: Session, settings: Settings, raw: str) -> IssuedSession:
    invalid = AppError("invalid_refresh_token", "Votre session a expiré.", 401)
    record = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == fingerprint(raw)))
    if record is None:
        raise invalid

    now = utcnow()
    if record.revoked_at is not None:
        # Révoquer et enregistrer avant de lever l'erreur
        db.execute(
            update(RefreshToken)
            .where(RefreshToken.family_id == record.family_id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        db.commit()
        raise invalid

    user = db.get(User, record.user_id)
    if as_utc(record.expires_at) <= now or user is None:
        raise invalid

    record.revoked_at = now
    db.add(record)
    return issue_session(db, settings, user, family_id=record.family_id)


def revoke_session(db: Session, raw: str) -> None:
    record = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == fingerprint(raw)))
    if record is None:
        return
    db.execute(
        update(RefreshToken)
        .where(RefreshToken.family_id == record.family_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=utcnow())
    )
    db.commit()


#  Inscription par e-mail


def email_status(db: Session, settings: Settings, email: str) -> tuple[bool, bool]:
    """Retourne (existe, vérifié)."""
    email = normalize_email(email)
    _check_email(email, settings)
    user = _find_user(db, email)
    return (user is not None, bool(user and user.is_verified))


def _send_verification(
    db: Session, settings: Settings, sender: EmailSender, user: User, *, respect_cooldown: bool
) -> None:
    now = utcnow()
    if respect_cooldown:
        last = db.scalar(
            select(EmailVerificationToken)
            .where(EmailVerificationToken.user_id == user.id)
            .order_by(EmailVerificationToken.created_at.desc())
        )
        if last is not None and (
            now - as_utc(last.created_at) < timedelta(seconds=settings.resend_cooldown_seconds)
        ):
            return

    raw = secrets.token_urlsafe(32)
    db.add(
        EmailVerificationToken(
            user_id=user.id,
            token_hash=hashlib.sha256(raw.encode()).hexdigest(),
            expires_at=now + timedelta(seconds=settings.verification_token_ttl_seconds),
        )
    )
    db.commit()
    link = f"{settings.public_base_url.rstrip('/')}/auth/verify?token={raw}"
    sender.send_verification(user.email, user.first_name or "", link)


def register(
    db: Session,
    settings: Settings,
    sender: EmailSender,
    *,
    email: str,
    first_name: str,
    last_name: str,
    password: str,
) -> None:
    email = normalize_email(email)
    _check_email(email, settings)
    try:
        first, last = clean_name(first_name), clean_name(last_name)
    except ValueError as exc:
        raise AppError("validation_error", "Prénom ou nom invalide.", 422) from exc
    if not MIN_PASSWORD <= len(password) <= MAX_PASSWORD or password.lower() == email:
        raise AppError("weak_password", "Ce mot de passe n'est pas assez solide.", 422)

    password_hash = hash_password(password)
    user = _find_user(db, email)
    if user is not None and user.is_verified:
        raise AppError("email_already_registered", "Un compte existe déjà avec cet e-mail.", 409)

    if user is None:
        user = User(email=email)
        db.add(user)
    # Une inscription abandonnée peut être reprise : on remplace les informations du compte
    # tant qu'il n'est pas vérifié, puisque seul le propriétaire de l'adresse pourra le confirmer.
    user.first_name, user.last_name, user.password_hash = first, last, password_hash
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise AppError(
            "email_already_registered", "Un compte existe déjà avec cet e-mail.", 409
        ) from None
    _send_verification(db, settings, sender, user, respect_cooldown=False)


def resend_verification(db: Session, settings: Settings, sender: EmailSender, email: str) -> None:
    """Réponse identique que le compte existe ou non"""
    user = _find_user(db, normalize_email(email))
    if user is not None and not user.is_verified:
        _send_verification(db, settings, sender, user, respect_cooldown=True)


def verify_email(db: Session, raw_token: str) -> bool:
    record = db.scalar(
        select(EmailVerificationToken).where(
            EmailVerificationToken.token_hash == hashlib.sha256(raw_token.encode()).hexdigest()
        )
    )
    if record is None or record.used_at is not None or as_utc(record.expires_at) <= utcnow():
        return False
    user = db.get(User, record.user_id)
    if user is None:
        return False
    record.used_at = utcnow()
    user.is_verified = True
    db.commit()
    return True


def login(db: Session, settings: Settings, *, email: str, password: str) -> IssuedSession:
    email = normalize_email(email)
    user = _find_user(db, email)
    now = utcnow()

    if user is not None and user.locked_until is not None and as_utc(user.locked_until) > now:
        raise AppError("too_many_attempts", "Trop de tentatives. Réessayez plus tard.", 429)

    valid = verify_password(password, user.password_hash if user else None)
    if user is None or not valid:
        if user is not None:
            user.failed_logins += 1
            if user.failed_logins >= settings.max_failed_logins:
                user.locked_until = now + timedelta(seconds=settings.login_lock_seconds)
                user.failed_logins = 0
            db.commit()
        raise AppError("invalid_credentials", "E-mail ou mot de passe incorrect.", 401)

    if not user.is_verified:
        raise AppError("email_not_verified", "Confirmez d'abord votre adresse e-mail.", 403)

    user.failed_logins = 0
    user.locked_until = None
    db.commit()
    return issue_session(db, settings, user)


# Google et Facebook


def sign_in_with_provider(
    db: Session, settings: Settings, verifier: TokenVerifier, token: str
) -> tuple[User, IssuedSession]:
    try:
        identity: ProviderIdentity = verifier.verify(token)
    except InvalidProviderToken as exc:
        raise AppError(
            "invalid_provider_token", "Connexion refusée par le fournisseur.", 401
        ) from exc

    if identity.email:
        _check_email(identity.email, settings)

    known = db.scalar(
        select(SocialIdentity).where(
            SocialIdentity.provider == identity.provider, SocialIdentity.subject == identity.subject
        )
    )
    if known is not None:
        user = db.get(User, known.user_id)
        if user is None:
            raise AppError("invalid_provider_token", "Connexion refusée par le fournisseur.", 401)
        return user, issue_session(db, settings, user)

    if not identity.email:
        raise AppError(
            "provider_email_missing", "Le fournisseur n'a pas communiqué d'adresse e-mail.", 422
        )

    user = _find_user(db, identity.email)
    if user is not None and not identity.email_trusted:
        # Facebook ne garantit pas que l'adresse appartient à la personne : rattacher la
        # connexion à un compte existant permettrait de le prendre en usurpant l'adresse.
        raise AppError(
            "account_exists_other_method",
            "Un compte existe déjà avec cette adresse. Connectez-vous avec l'autre méthode.",
            409,
        )
    if user is None:
        user = User(email=identity.email, is_verified=True)
        db.add(user)
    else:
        # Google garantit l'adresse : le compte est rattaché, et confirmé par la même occasion.
        user.is_verified = True
    try:
        db.flush()
        db.add(
            SocialIdentity(user_id=user.id, provider=identity.provider, subject=identity.subject)
        )
        db.commit()
    except IntegrityError:
        db.rollback()
        raise AppError("account_conflict", "Ce compte ne peut pas être créé.", 409) from None
    return user, issue_session(db, settings, user)
