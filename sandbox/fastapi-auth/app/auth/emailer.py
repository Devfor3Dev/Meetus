"""Envoi du courriel de confirmation.

L'API d'essai se contente de l'écrire dans la console : copiez le lien affiché et
ouvrez-le dans le navigateur du téléphone pour simuler le clic sur l'e-mail. Un vrai
envoi (SMTP, service transactionnel) sra à remplacer par la alsse.
"""

import logging
from typing import Protocol

logger = logging.getLogger("loveline.email")


class EmailSender(Protocol):
    def send_verification(self, to: str, first_name: str, link: str) -> None: ...


class ConsoleEmailSender:
    def send_verification(self, to: str, first_name: str, link: str) -> None:
        logger.warning("Courriel de confirmation pour %s (%s) : %s", to, first_name, link)
