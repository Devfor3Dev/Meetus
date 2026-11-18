"""Hachage des mots de passe avec Argon2."""

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

_hasher = PasswordHasher()

# Empreinte d'un mot de passe quelconque, comparée quand le compte n'existe pas, pour
# que le temps de réponse ne distingue pas un compte inconnu d'un mot de passe faux.
_DUMMY_HASH = _hasher.hash("mot-de-passe-factice-sans-valeur")


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    try:
        return _hasher.verify(password_hash or _DUMMY_HASH, password) and password_hash is not None
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False
