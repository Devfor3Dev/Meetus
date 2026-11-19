"""Jetons d'accès signés et empreintes des jetons de renouvellement."""

import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta

import jwt

_ALGORITHM = "HS256"


def utcnow() -> datetime:
    return datetime.now(UTC)


def as_utc(value: datetime) -> datetime:
    """SQLite rend des dates sans fuseau : on les relit comme de l'UTC."""
    return value if value.tzinfo else value.replace(tzinfo=UTC)


def encode_access_token(user_id: str, secret: str, ttl_seconds: int) -> str:
    now = utcnow()
    claims = {
        "sub": user_id,
        "typ": "access",
        "jti": uuid.uuid4().hex,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=ttl_seconds)).timestamp()),
    }
    return jwt.encode(claims, secret, algorithm=_ALGORITHM)


def decode_access_token(token: str, secret: str) -> str | None:
    try:
        claims = jwt.decode(
            token,
            secret,
            algorithms=[_ALGORITHM],
            options={"require": ["exp", "iat", "sub", "typ"]},
            leeway=5,
        )
    except jwt.PyJWTError:
        return None
    return str(claims["sub"]) if claims.get("typ") == "access" else None


def new_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def fingerprint(token: str) -> str:
    """Seule cette empreinte est stockée"""
    return hashlib.sha256(token.encode()).hexdigest()
