# Loveline — FastAPI Sandbox Authentication Server

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Docker](https://img.shields.io/badge/Docker-Supported-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![Pytest](https://img.shields.io/badge/Tests-Pytest_Passing-0A9EDC?style=for-the-badge&logo=pytest&logoColor=white)]()

Ce serveur d'essai léger basé sur **FastAPI** implémente l'intégralité du contrat d'authentification ([docs/contrat-api-auth.md](../../docs/contrat-api-auth.md)) pour l'application mobile Loveline. Il permet de développer, tester et simuler le flux d'authentification complet (Inscription, Connexion E-mail, Google OAuth, Facebook Login, Jetons JWT et Lien de confirmation) sans nécessiter de backend de production.

---

## 📋 Table des matières

- [Fonctionnalités & Architecture](#-fonctionnalités--architecture)
- [Prérequis](#-prérequis)
- [Installation & Démarrage Rapide](#-installation--démarrage-rapide)
  - [Option A : Exécution Native (Python / Virtualenv)](#option-a--exécution-native-python--virtualenv)
  - [Option B : Exécution via Docker Compose](#option-b--exécution-via-docker-compose)
- [Configuration des Variables d'Environnement](#-configuration-des-variables-denvironnement)
- [Simulation de la Vérification par E-mail & Deep Link](#-simulation-de-la-vérification-par-e-mail--deep-link)
- [Exposition Réseau & Tunnels (Ngrok)](#-exposition-réseau--tunnels-ngrok)
- [Documentation des Endpoints API](#-documentation-des-endpoints-api)
- [Tests Automatisés & Qualité](#-tests-automatisés--qualité)

---

## 🏗️ Fonctionnalités & Architecture

- **Gestion des sessions JWT :** Émission de jetons d'accès éphémères (`Bearer Token`) et de jetons de rafraîchissement sécurisés (`HttpOnly Cookie`).
- **Rotation & Révocation :** Révocation automatique des sessions en cas de réutilisation frauduleuse de jetons.
- **Support Multi-fournisseurs :** Validation des jetons d'identité Google et Facebook avec vérification côté serveur.
- **Sécurité anti-brute-force :** Verrouillage automatique des comptes après 5 échecs consécutifs.
- **Base de données polyvalente :** Fonctionne nativement sur **SQLite** en développement local, ou **PostgreSQL** via Docker Compose.

---

## 🛠️ Prérequis

- **Python :** `>= 3.11`
- **Pip** & **Virtualenv**
- **Docker** et **Docker Compose** *(optionnel, pour l'environnement conteneurisé)*

---

## 🚀 Installation & Démarrage Rapide

### Option A : Exécution Native (Python / Virtualenv)

1. **Créer et activer un environnement virtuel :**
   ```bash
   # Linux / macOS
   python3 -m venv .venv
   source .venv/bin/activate

   # Windows (PowerShell)
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   ```

2. **Installer les dépendances de développement :**
   ```bash
   pip install -r requirements-dev.txt
   ```

3. **Configurer l'environnement :**
   ```bash
   cp .env.example .env
   ```
   *Éditez le fichier `.env` pour générer une valeur sécurisée pour `JWT_SECRET`.*

4. **Appliquer les migrations de la base de données (Alembic) :**
   ```bash
   alembic upgrade head
   ```

5. **Démarrer le serveur Uvicorn :**
   ```bash
   uvicorn app.main:app_factory --factory --host 0.0.0.0 --port 8000 --reload
   ```

---

### Option B : Exécution via Docker Compose

Pour démarrer une instance complète avec une base de données **PostgreSQL** dédiée :

```bash
docker compose up --build
```

L'API sera accessible sur `http://localhost:8000`.

---

## ⚙️ Configuration des Variables d'Environnement

Le fichier `.env` accepte les paramètres suivants :

| Variable | Description | Valeur par défaut | Obligatoire |
| --- | --- | --- | --- |
| `JWT_SECRET` | Clé secrète de signature des jetons JWT | *Aucune* | **Oui** |
| `PUBLIC_BASE_URL` | URL publique du serveur pour générer les liens e-mail | `http://localhost:8000` | **Oui** |
| `COOKIE_SECURE` | Exige HTTPS pour le cookie `refresh_token` (`false` en dev HTTP) | `false` | Non |
| `DATABASE_URL` | URL de connexion SQLAlchemy (SQLite / PostgreSQL) | `sqlite:///./sandbox.db` | Non |
| `GOOGLE_CLIENT_ID` | Client ID OAuth Web pour vérifier les jetons Google | *Vide* | Pour Google |
| `FACEBOOK_APP_ID` | Identifiant d'application Facebook | *Vide* | Pour Facebook |
| `FACEBOOK_APP_SECRET` | Clé secrète d'application Facebook | *Vide* | Pour Facebook |
| `ALLOWED_EMAIL_DOMAINS` | Domaines autorisés (ex: `univ.fr,student.fr`) | *Vide (Autorise tout)* | Non |

---

## 📩 Simulation de la Vérification par E-mail & Deep Link

En environnement Sandbox local, l'envoi d'e-mails réels est désactivé. Le serveur simule l'envoi d'e-mails en affichant l'URL de vérification directement dans la **console terminal** :

1. Lors de l'inscription d'un nouvel utilisateur, le terminal affiche :
   ```text
   ================================================================================
   LIEN DE CONFIRMATION D'E-MAIL :
   http://localhost:8000/auth/verify?token=eyJhbGciOi...
   ================================================================================
   ```
2. Ouvrez ce lien dans votre navigateur ou directement sur le téléphone.
3. Le lien renvoie une page web qui déclenche le Deep Link `loveline://verified` pour ramener automatiquement l'utilisateur dans l'application mobile Loveline.

---

## 🌐 Exposition Réseau & Tunnels (Ngrok)

Pour permettre à un **téléphone physique** de contacter le serveur Sandbox local :

1. **Lancer Ngrok :**
   ```bash
   ngrok http 8000
   ```
2. **Reporter l'URL HTTPS générée dans votre fichier `.env` :**
   ```env
   PUBLIC_BASE_URL=https://a1b2-34-89-10.ngrok-free.app
   ```
3. **Redémarrer Uvicorn** pour prendre en compte l'adresse du serveur.

---

## 📡 Documentation des Endpoints API

Toutes les réponses d'erreur suivent le format standardisé `{"error": {"code": "...", "message": "..."}}`.

| Endpoint | Méthode | Rôle |
| --- | --- | --- |
| `POST /auth/check-email` | `POST` | Vérifie l'existence et l'état de vérification d'un compte. |
| `POST /auth/register` | `POST` | Inscription initiale (envoie l'e-mail de confirmation). |
| `GET /auth/verify` | `GET` | Valide le jeton e-mail et redirige vers `loveline://verified`. |
| `POST /auth/login` | `POST` | Authentification e-mail / mot de passe. |
| `POST /auth/google` | `POST` | Connexion OAuth via Google ID Token. |
| `POST /auth/facebook` | `POST` | Connexion via Facebook Access Token. |
| `POST /auth/refresh` | `POST` | Renouvellement du jeton d'accès via le cookie `refresh_token`. |
| `POST /auth/logout` | `POST` | Révocation de la session en cours. |
| `GET /auth/me` | `GET` | Récupère le profil de l'utilisateur connecté. |
| `PATCH /auth/me` | `PATCH` | Met à jour le nom et prénom de l'utilisateur. |

---

## 🧪 Tests Automatisés & Qualité

Le projet Sandbox dispose d'une suite de 42 tests d'intégration couvrant le comportement complet des sessions et de la sécurité :

```bash
# Exécuter l'ensemble des tests Pytest
pytest

# Lancer l'analyse statique et le formateur Ruff
ruff check .
ruff format --check .

# Vérifier la cohérence des migrations Alembic
alembic check
```
