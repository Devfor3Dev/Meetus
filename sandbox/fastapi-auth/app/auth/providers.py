"""Vérification des jetons Google et Facebook.

Le téléphone obtient un jeton chez le fournisseur et l'envoie à l'API :
un jeton émis pour une autre application doit être refusé.
"""

from dataclasses import dataclass
from typing import Protocol

import cachecontrol
import requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

GRAPH_URL = "https://graph.facebook.com"


class InvalidProviderToken(Exception):
    pass


@dataclass(frozen=True)
class ProviderIdentity:
    provider: str
    subject: str
    email: str | None

    # True quand le fournisseur garantit que l'adresse appartient à la personne. Seul
    # ce cas autorise de rattacher la connexion à un compte déjà existant.
    email_trusted: bool


class TokenVerifier(Protocol):
    def verify(self, token: str) -> ProviderIdentity: ...


class GoogleVerifier:
    def __init__(self, client_id: str) -> None:
        self._client_id = client_id
        # Les certificats publics de Google changent rarement : on les garde en cache HTTP.
        session = cachecontrol.CacheControl(requests.Session())
        self._request = google_requests.Request(session=session)

    def verify(self, token: str) -> ProviderIdentity:
        if not self._client_id:
            raise InvalidProviderToken("GOOGLE_CLIENT_ID n'est pas configuré.")
        try:
            claims = id_token.verify_oauth2_token(token, self._request, audience=self._client_id)
        except Exception as exc:
            raise InvalidProviderToken(str(exc)) from exc
        subject, email = claims.get("sub"), claims.get("email")
        if not subject:
            raise InvalidProviderToken("Jeton sans identifiant.")
        return ProviderIdentity(
            provider="google",
            subject=str(subject),
            email=str(email).lower() if email else None,
            email_trusted=bool(claims.get("email_verified")) and bool(email),
        )


class FacebookVerifier:
    """Contrôle le jeton auprès de Facebook : validité, application destinataire, identifiant."""

    def __init__(self, app_id: str, app_secret: str) -> None:
        self._app_id = app_id
        self._app_secret = app_secret

    def verify(self, token: str) -> ProviderIdentity:
        if not self._app_id or not self._app_secret:
            raise InvalidProviderToken("FACEBOOK_APP_ID ou FACEBOOK_APP_SECRET manquant.")
        try:
            debug = requests.get(
                f"{GRAPH_URL}/debug_token",
                params={"input_token": token, "access_token": f"{self._app_id}|{self._app_secret}"},
                timeout=8,
            ).json()
            data = debug.get("data", {})
            if not data.get("is_valid") or str(data.get("app_id")) != self._app_id:
                raise InvalidProviderToken(
                    "Jeton Facebook invalide ou destiné à une autre application."
                )
            profile = requests.get(
                f"{GRAPH_URL}/me",
                params={"fields": "id,email", "access_token": token},
                timeout=8,
            ).json()
        except InvalidProviderToken:
            raise
        except Exception as exc:
            raise InvalidProviderToken(str(exc)) from exc

        subject, email = profile.get("id"), profile.get("email")
        if not subject or str(subject) != str(data.get("user_id")):
            raise InvalidProviderToken("Identifiant Facebook incohérent.")
        # Facebook ne dit pas si l'adresse est vérifiée : on va pas utiliser ça pour
        # rattacher la connexion à un compte existant.
        return ProviderIdentity(
            provider="facebook",
            subject=str(subject),
            email=str(email).lower() if email else None,
            email_trusted=False,
        )
