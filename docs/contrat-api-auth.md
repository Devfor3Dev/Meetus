# Contrat d'authentification entre l'application et le backend

Ce document décrit ce que l'application mobile attend du backend pour l'inscription et la connexion. Il reprend le contrat de l'application de bus (`/auth/check-email`, `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/me`, lien de confirmation par e-mail) et y ajoute Google, Facebook et le prénom et le nom séparés. Le serveur d'essai de [sandbox/fastapi-auth](../../../Documents/loveline%20(1)/repo/sandbox/fastapi-auth/README.md) l'implémente en entier, avec des tests. L'équipe Django peut s'en servir comme référence.

## Les parcours

Pour une inscription par e-mail, l'application demande l'adresse, appelle `check-email`, puis `register` avec le prénom, le nom et le mot de passe. Le serveur crée le compte non vérifié et envoie un e-mail contenant un lien vers `GET /auth/verify`. Ce lien confirme l'adresse et sert une page qui ouvre `loveline://verified`. L'application, qui écoutait ce lien, appelle alors `login` avec le mot de passe qu'elle a gardé quelques minutes en mémoire, puis affiche l'écran de bienvenue.

Pour un compte existant et vérifié, l'application passe directement au mot de passe. Pour un compte existant mais non vérifié, elle reprend à l'étape « vérifiez votre boîte mail », puis demande le mot de passe une fois le lien ouvert.

Pour Google et Facebook, l'application obtient un jeton chez le fournisseur et l'envoie au serveur, qui le vérifie auprès du fournisseur et ouvre la session. Si le prénom et le nom manquent, la réponse porte `needs_identity: true` et l'application les demande avant d'afficher la bienvenue.

## Les appels

| Appel | Entrée | Réponse |
| --- | --- | --- |
| `POST /auth/check-email` | `{"email"}` | 200 `{"exists", "is_verified"}` |
| `POST /auth/register` | `{"email", "first_name", "last_name", "password"}` | 202, le compte est créé non vérifié et l'e-mail part |
| `POST /auth/resend-verification` | `{"email"}` | 202, toujours la même réponse |
| `GET /auth/verify?token=...` | le jeton du lien | 200 avec une page HTML qui redirige vers `loveline://verified`, ou 400 si le lien est invalide, expiré ou déjà utilisé |
| `POST /auth/login` | `{"email", "password"}` | 200 `{"access_token", "token_type", "expires_in"}` et le cookie `refresh_token` |
| `POST /auth/google` | `{"id_token"}` | 200 avec `access_token`, `token_type`, `expires_in` et `user`, plus le cookie |
| `POST /auth/facebook` | `{"access_token"}` | comme Google |
| `POST /auth/refresh` | cookie `refresh_token` | 200 `{"access_token", ...}` et le cookie remplacé |
| `POST /auth/logout` | cookie `refresh_token` | 204, session révoquée, cookie effacé |
| `GET /auth/me` | en-tête `Authorization: Bearer ...` | 200 `user` |
| `PATCH /auth/me` | Bearer et `{"first_name", "last_name"}` | 200 `user` |

L'objet `user` contient `id`, `email`, `first_name`, `last_name`, `is_verified` et `needs_identity`.

## Les erreurs

Toutes les erreurs ont la forme `{"error": {"code": "...", "message": "..."}}`, et le code ne change jamais. L'application affiche ses propres messages à partir des codes qu'elle connaît.

| Code | Statut | Sens |
| --- | --- | --- |
| `invalid_credentials` | 401 | e-mail inconnu ou mot de passe faux, indiscernables l'un de l'autre |
| `email_not_verified` | 403 | le compte existe mais l'adresse n'est pas confirmée |
| `too_many_attempts` | 429 | compte verrouillé après cinq échecs |
| `email_already_registered` | 409 | inscription sur une adresse déjà vérifiée |
| `email_domain_not_allowed` | 403 | domaine hors de la liste de l'établissement |
| `weak_password` | 422 | mot de passe hors de 8 à 128 caractères |
| `validation_error` | 422 | champ invalide, par exemple un prénom avec un chiffre |
| `invalid_provider_token` | 401 | jeton Google ou Facebook refusé |
| `provider_email_missing` | 422 | le fournisseur n'a pas donné d'adresse e-mail |
| `account_exists_other_method` | 409 | connexion Facebook sur une adresse déjà inscrite |
| `invalid_refresh_token` | 401 | session expirée ou révoquée |
| `unauthorized` | 401 | jeton d'accès absent ou invalide |

## Ce que le backend doit garantir

Le jeton de renouvellement ne figure jamais dans le corps d'une réponse. Il voyage dans un cookie HttpOnly, SameSite Strict, au chemin `/auth`, que le cookie jar de l'application garde et renvoie seul. Il ne sert qu'une fois : chaque renouvellement le remplace, et si un jeton déjà utilisé revient, toute la session est révoquée.

Les jetons Google et Facebook sont contrôlés auprès du fournisseur, y compris l'application destinataire : un jeton émis pour une autre application doit être refusé. Une connexion Google peut être rattachée à un compte existant portant la même adresse, parce que Google garantit l'adresse. Une connexion Facebook ne l'est jamais, parce que Facebook ne garantit rien : elle répond `account_exists_other_method`.

Le lien de confirmation est à usage unique et expire. Seule l'empreinte des jetons est stockée.

## Un compromis à connaître

`check-email` révèle si une adresse a un compte, parce que l'écran de saisie doit savoir s'il propose l'inscription ou la connexion. Dans une application de rencontre, savoir qu'une personne y est inscrite est une information sensible. Le serveur d'essai limite le risque en gardant `resend-verification` muet, mais l'équipe devrait décider si ce compromis lui convient, ou ajouter une limitation de débit devant cet appel.
