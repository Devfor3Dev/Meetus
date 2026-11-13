# Loveline Mobile Dating Application

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_2.6-00599C?style=for-the-badge)](https://riverpod.dev)
[![FastAPI](https://img.shields.io/badge/Sandbox_Backend-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](sandbox/fastapi-auth)

**Loveline** est une application mobile de rencontre pour l'université de Kara axée sur la simplicité, la sécurité et la proximité sur le campus. Ce dépôt contient le client mobile Flutter (Android & iOS) couvrant le parcours d'onboarding complet, l'authentification multi-fournisseurs (E-mail, Google, Facebook), la gestion avancée des sessions et la protection des données.

---

##  Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Architecture & Principes de Conception](#-architecture--principes-de-conception)
- [Diagrammes de Flux d'Authentification](#-diagrammes-de-flux-dauthentification)
- [Prérequis](#-prérequis)
- [Installation & Démarrage](#-installation--démarrage)
- [Environnement de Développement & Réseau](#-environnement-de-développement--réseau)
  - [1. Émulateur Android (Localhost)](#1-émulateur-android-localhost)
  - [2. Appareil Physique avec Tunnel Ngrok](#2-appareil-physique-avec-tunnel-ngrok)
- [Configuration du Backend de Test (FastAPI Sandbox)](#-configuration-du-backend-de-test-fastapi-sandbox)
- [Configuration des Fournisseurs OAuth (Google & Facebook)](#-configuration-des-fournisseurs-oauth-google--facebook)
- [Documentation de l'API (Contrat d'Authentification)](#-documentation-de-lapi-contrat-dauthentification)
- [Structure du Projet](#-structure-du-projet)
- [Tests & Assurance Qualité](#-tests--assurance-qualité)
- [CI/CD & Déploiement](#-cicd--déploiement)

---

##  Fonctionnalités

- **Onboarding Immersif :** Carrousel multi-diapositive avec effet parallaxe, animations fluides basées sur la position du doigt et support de l'accessibilité.
- **Authentification Sécurisée & Souple :**
  - Inscription et connexion par **E-mail / Mot de passe**.
  - Connexion rapide via **Google OAuth 2.0** et **Facebook Login**.
  - Vérification obligatoire de l'e-mail par Lien Profond (*Deep Link* `loveline://verified`).
- **Gestion des Profils & Sessions :**
  - Collecte guidée du nom et prénom.
  - Stockage sécurisé des jetons JWT via Keychain (iOS) et EncryptedSharedPreferences (Android).
  - Renouvellement automatique du jeton d'accès via Cookie de rafraîchissement (`HttpOnly`).
- **Sécurité et Confidentialité :**
  - Protection contre les captures d'écran et enregistrements vidéos (`FLAG_SECURE` sous Android).
  - Verrouillage automatique de la saisie après 5 tentatives infructueuses.

---

##  Architecture & Principes de Conception

Le projet adopte une **Architecture Propre en Couches (Clean / Layered Architecture)** combinée avec la gestion d'état **Riverpod** et l'injection de dépendances via **GetIt** / **Injectable**.

```
                           ┌───────────────────────────┐
                           │    Presentation Layer     │
                           │ (Widgets, Screens, Views) │
                           └─────────────┬─────────────┘
                                         │
                                         ▼
                           ┌───────────────────────────┐
                           │     Application Layer     │
                           │  (Controllers, Riverpod)  │
                           └─────────────┬─────────────┘
                                         │
                                         ▼
                           ┌───────────────────────────┐
                           │       Domain Layer        │
                           │ (Entities, Exceptions)    │
                           └─────────────┬─────────────┘
                                         │
                                         ▼
                           ┌───────────────────────────┐
                           │        Data Layer         │
                           │ (Repositories, API, Storage)│
                           └───────────────────────────┘
```

- **Découplage strict :** Aucun écran ne gère la navigation directe. Le routeur (`GoRouter`) écoute l'état de la session et effectue les redirections automatiquement.
- **Ressources isolées :** Les intégrations tierces (Google Sign-In, Facebook Auth, Secure Storage) sont encapsulées derrière des sources de données et dépôts abstraits.

---

##  Diagrammes de Flux d'Authentification

### Flux Général de Redirection
```
                       +-----------------------+
                       |   Lancement de l'app  |
                       +-----------+-----------+
                                   |
                         [Onboarding vu ?]
                            /         \
                         Non           Oui
                         /               \
            +-------------------+   [Connecté ?]
            | Ecran Onboarding  |     /      \
            +-------------------+   Non      Oui
                                    /          \
                +----------------------+   [Nom & Prénom renseignés ?]
                | Flux d'Auth (Step 1) |          /               \
                +----------------------+       Non                Oui
                                                /                   \
                                  +----------------------+   +----------------+
                                  | Flux d'Auth (Identity)|  | Accueil (Home) |
                                  +----------------------+   +----------------+
```

### Inscription E-mail & Vérification Deep Link
```
 User                 Mobile App                 Backend Sandbox               Mail Server
  │                       │                             │                           │
  │─── Saisie E-mail ────>│── POST /auth/check-email ──>│                           │
  │                       │<── {exists: false} ─────────│                           │
  │─── Nom & Password ───>│── POST /auth/register ─────>│                           │
  │                       │                             │── Envoi E-mail Verif. ───>│
  │                       │<── 202 Accepted ────────────│                           │
  │                       │                             │                           │
  │── En attente du lien ─│                             │                           │
  │                       │                             │                           │
  │── Clic Lien Mail ──────────────────────────────────────────────────────────────>│
  │                       │                             │<── GET /auth/verify ──────│
  │                       │<── Redirection Deep Link ───│                           │
  │                       │    loveline://verified      │                           │
  │                       │                             │                           │
  │                       │── POST /auth/login ────────>│                           │
  │                       │<── 200 OK (Tokens JWT) ─────│                           │
  │<── Ecran Bienvenue ───│                             │                           │
```

---

## 🛠️ Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

- **Flutter SDK :** `>= 3.27.0` (Dart SDK `>= 3.6.0`)
- **Android Studio / VS Code** avec les extensions Flutter et Dart.
- **Android SDK & NDK** (pour la compilation Android).
- **Xcode** (15+ requises pour la compilation iOS sur macOS).
- **Python 3.11+** & **Pip** (si vous lancez le serveur backend Sandbox local).
- **Ngrok** (optionnel, pour exposer le serveur local aux téléphones physiques).

---

##  Installation & Démarrage

### 1. Cloner le projet
```bash
git clone https://github.com/votre-organisation/loveline.git
cd loveline
```

### 2. Installer les dépendances Flutter
```bash
flutter pub get
```

### 3. Générer le code d'injection de dépendances
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Vérifier la conformité du code
```bash
flutter analyze
flutter test
```

---

##  Environnement de Développement & Réseau

L'application communique avec l'API backend via la variable d'environnement `API_BASE_URL` configurée au moment du lancement.

### 1. Émulateur Android (Localhost)
L'émulateur Android redirige l'adresse `10.0.2.2` vers le `localhost` (`127.0.0.1`) de votre machine hôte.

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=votre-web-client-id.apps.googleusercontent.com
```

### 2. Appareil Physique avec Tunnel Ngrok
Pour tester l'application sur un **téléphone Android ou iOS réel**, l'appareil doit pouvoir accéder au serveur backend. L'utilisation d'un tunnel sécurisé HTTPS **Ngrok** est recommandée.

1. **Lancer le backend local (Port 8000) :**
   ```bash
   cd sandbox/fastapi-auth
   uvicorn app.main:app_factory --factory --host 0.0.0.0 --port 8000 --reload
   ```

2. **Démarrer un tunnel Ngrok :**
   ```bash
   ngrok http 8000
   ```
   *Exemple de sortie Ngrok :* `Forwarding https://a1b2-34-89-10.ngrok-free.app -> http://localhost:8000`

3. **Mettre à jour `PUBLIC_BASE_URL` dans le backend `.env` :**
   ```env
   PUBLIC_BASE_URL=https://a1b2-34-89-10.ngrok-free.app
   ```

4. **Lancer l'application Flutter vers l'URL Ngrok :**
   ```bash
   flutter run \
     --dart-define=API_BASE_URL=https://a1b2-34-89-10.ngrok-free.app \
     --dart-define=GOOGLE_SERVER_CLIENT_ID=votre-web-client-id.apps.googleusercontent.com
   ```

---

## Configuration des Fournisseurs OAuth (Google & Facebook)

### Google Authentication Setup

1. Rendez-vous sur la [Google Cloud Console](https://console.cloud.google.com/).
2. Créez un projet et configurez l'écran de consentement OAuth.
3. Créez un **ID client OAuth de type Application Web** :
   - Utilisez sa valeur comme `GOOGLE_SERVER_CLIENT_ID` dans Flutter et `GOOGLE_CLIENT_ID` dans le backend.
4. Créez un **ID client OAuth de type Android** :
   - **Nom du package :** `com.example.loveline`
   - **Empreinte SHA-1 :** Générez la clé SHA-1 de débogage :
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

### Facebook Login Setup

1. Rendez-vous sur [Facebook for Developers](https://developers.facebook.com/).
2. Créez une application et activez le produit **Facebook Login**.
3. Déclarez les clés dans les fichiers natifs `AndroidManifest.xml` et `Info.plist` en suivant la documentation officielle du package `flutter_facebook_auth`.

---

##  Documentation de l'API (Contrat d'Authentification)

Le backend (Sandbox ou Django) doit implémenter les points de terminaison suivants :

| Endpoint | Méthode | Description | Payload d'entrée | Réponse succès |
| --- | --- | --- | --- | --- |
| `/auth/check-email` | `POST` | Vérifie si l'e-mail existe | `{"email": "string"}` | `200 OK` `{"exists": bool, "is_verified": bool}` |
| `/auth/register` | `POST` | Inscription initiale | `{"email", "first_name", "last_name", "password"}` | `202 Accepted` |
| `/auth/verify` | `GET` | Validation du jeton e-mail | Query param: `?token=...` | `200 OK` (Redirige vers `loveline://verified`) |
| `/auth/login` | `POST` | Connexion classique | `{"email", "password"}` | `200 OK` + Cookie `refresh_token` |
| `/auth/google` | `POST` | Connexion OAuth Google | `{"id_token": "string"}` | `200 OK` + `User` object |
| `/auth/facebook` | `POST` | Connexion OAuth Facebook | `{"access_token": "string"}` | `200 OK` + `User` object |
| `/auth/refresh` | `POST` | Renouvellement de session | Cookie `refresh_token` | `200 OK` + nouveau jeton d'accès |
| `/auth/logout` | `POST` | Déconnexion | Bearer Token | `204 No Content` |
| `/auth/me` | `GET` / `PATCH` | Profil de l'utilisateur courant | Bearer Token | `200 OK` `User` object |

*Pour plus de détails sur la gestion des erreurs et des codes d'état, consultez [docs/contrat-api-auth.md](docs/contrat-api-auth.md).*

---

##  Structure du Projet

```
loveline/
├── android/                   # Configuration native Android (Manifest, Keystore, Gradle)
├── assets/                    # Ressources statiques (Images, Logos, Polices Exo 2)
│   ├── fonts/
│   └── images/
│       ├── brand/             # Logos de marque (Logo Loveline, Google, Facebook)
│       └── onboarding/        # Photos du carrousel d'onboarding (slide_1, 2, 3)
├── docs/                      # Documentation technique et spécifications d'architecture
│   ├── ci-cd.md
│   └── contrat-api-auth.md
├── ios/                       # Configuration native iOS (Info.plist, Pods)
├── lib/                       # Code source principal de l'application Flutter
│   ├── main.dart              # Point d'entrée de l'application
│   ├── app.dart               # Configuration MaterialApp, Thèmes et Routeur
│   ├── core/                  # Éléments partagés et infrastructure
│   │   ├── animation/         # Courbes et gestion de défilement
│   │   ├── constants/         # Chemins d'assets et clés de stockage
│   │   ├── di/                # Injection de dépendances (GetIt / Injectable)
│   │   ├── network/           # Client Dio, Intercepteurs JWT & Refresh
│   │   ├── router/            # GoRouter & Redirections dynamiques
│   │   ├── security/          # Protection contre les captures d'écran
│   │   ├── storage/           # Secure Storage & SharedPreferences
│   │   ├── theme/             # Palette de couleurs WCAG & Typographies
│   │   └── widgets/           # Composants UI réutilisables (Boutons, Champs)
│   └── features/              # Modules métier (Domain Driven Design)
│       ├── auth/              # Module d'authentification complète
│       └── onboarding/        # Module de présentation initiale
├── sandbox/                   # Environnement de test local
│   └── fastapi-auth/          # Backend d'essai léger en Python FastAPI
└── test/                      # Tests unitaires, de contrôleurs et d'interface
```

---

##  Tests & Assurance Qualité

Le projet inclut une suite complète de tests automatiques (unitaires, de widgets et de comportement du routeur).

```bash
# Exécuter l'ensemble des tests
flutter test

# Générer le rapport de couverture de code
flutter test --coverage
```

---

##  CI/CD & Déploiement

Le projet utilise **GitHub Actions** pour valider et compiler l'application à chaque mise à jour :

- **Mobile CI (`.github/workflows/mobile-ci.yml`) :** Analyse statique (`flutter analyze`), validation du formateur de code (`dart format`), exécution des tests unitaires et compilation d'un APK Debug.
- **Mobile Release (`.github/workflows/mobile-release.yml`) :** Génération automatique d'un App Bundle (`.aab`) et APK d'installation signés lors de la création d'un tag de version (`mobile-v*`).

---

##  Licence

Ce projet est sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus d'informations.
