# Pipelines et Docker

Six workflows GitHub Actions et trois Dockerfiles couvrent l'application mobile, le backend Django de l'équipe et le serveur d'essai FastAPI. Chaque workflow ne s'exécute que lorsque les fichiers de son dossier changent, donc un correctif dans `mobile/` ne relance pas les tests du backend.

## Les workflows

| Fichier | Déclencheur | Ce qu'il fait |
| --- | --- | --- |
| `backend-ci.yml` | pull request et push sur main touchant `backend/` | erreurs graves avec ruff, contrôles Django, migrations oubliées, migrations et tests sur PostgreSQL, audit des dépendances, construction de l'image et démarrage de Django dedans |
| `backend-cd.yml` | push sur main, tag `v*` | relance la CI, publie l'image sur GitHub Container Registry, appelle l'adresse de déploiement si elle est configurée |
| `mobile-ci.yml` | pull request et push sur main touchant `mobile/` | formatage, injection générée à jour, analyse, tests avec couverture, APK de debug |
| `mobile-release.yml` | tag `mobile-v*` | relance la CI, compile le bundle et l'APK signés, les range comme artefacts, efface la clé de signature |
| `sandbox-ci.yml` | pull request et push touchant `sandbox/fastapi-auth/` | lint, migrations et tests du serveur d'essai, sans publication |
| `dependabot.yml` | chaque semaine | propose les mises à jour des paquets Dart et Python, des images Docker et des actions |

## Ce que les pipelines du backend supposent

Le code du backend Django n'est pas dans ce dépôt, donc les pipelines reposent sur des hypothèses listées dans [backend/README.md](../../../Documents/loveline%20(1)/repo/backend/README.md) : projet dans `backend/`, dépendances dans `requirements.txt`, configuration lue dans l'environnement, base PostgreSQL. Les noms de variables d'environnement du bloc `env` de `backend-ci.yml` sont à aligner avec les réglages réels de l'équipe. Deux variables Actions facultatives permettent d'ajuster le reste sans modifier les fichiers : `DJANGO_SETTINGS_MODULE` et `DJANGO_WSGI_MODULE`.

La vérification de qualité du backend est volontairement limitée aux erreurs graves, pour ne pas bloquer une base de code qui existe déjà. L'équipe peut resserrer la sélection de règles quand elle les aura décidées.

## À configurer une fois

Dans les réglages du dépôt, onglet Secrets and variables, puis Actions.

| Nom | Type | Usage |
| --- | --- | --- |
| `DEPLOY_HOOK_URL` | secret | adresse d'appel de l'hébergeur pour redéployer, par exemple celle de Render. Sans elle, l'image est publiée et rien n'est déployé |
| `ANDROID_KEYSTORE_BASE64` | secret | le fichier de clé de signature encodé, avec `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | secrets | les informations de cette clé |
| `API_BASE_URL` | variable | adresse https du backend, vérifiée par le workflow de release |
| `GOOGLE_SERVER_CLIENT_ID` | variable | identifiant client OAuth de type Web |
| `DJANGO_SETTINGS_MODULE`, `DJANGO_WSGI_MODULE` | variables | facultatives, voir plus haut |

Recommandé aussi : protéger la branche main et exiger les contrôles `Qualité du code`, `Tests sur PostgreSQL`, `Analyse et tests` avant toute fusion.

## Trois choses à faire au premier passage

Premièrement, versionner les dossiers `android/` et `ios/` créés par `flutter create`. Sans eux, la compilation Android est ignorée avec un avertissement et la release s'arrête avec une erreur claire.

Deuxièmement, exécuter `dart format .` puis `dart run build_runner build --delete-conflicting-outputs` dans `mobile/` et versionner le résultat. Le fichier `injection.config.dart` livré a été écrit à la main au format d'injectable, et la CI refuse un fichier différent de celui que le générateur produit. Si elle échoue la première fois, c'est le comportement voulu : versionnez le fichier régénéré.

Troisièmement, brancher la signature Android. Le workflow écrit `android/key.properties`, mais Gradle doit le lire. Dans `android/app/build.gradle.kts`, ajoutez la lecture du fichier et une configuration de signature `release`, en suivant la page « Build and release an Android app » de la documentation Flutter, dont le contenu dépend de la version installée.

## Docker

```bash
docker compose up --build                                        # backend Django et PostgreSQL
docker compose --profile tools run --rm mobile-check             # analyse et tests du mobile dans un conteneur
docker build --target apk -t loveline-mobile:apk mobile          # APK de debug
cd sandbox/fastapi-auth && docker compose up --build             # serveur d'essai
```

Les images du backend et du serveur d'essai sont construites en deux étapes, tournent avec un utilisateur sans privilège et déclarent un contrôle de santé. Les migrations Django ne sont pas lancées au démarrage du conteneur : avec plusieurs instances, deux migrations simultanées seraient dangereuses. Lancez `python manage.py migrate` comme étape de déploiement, avant de démarrer la nouvelle version.

L'image du mobile ne sert pas à exécuter l'application. Elle reproduit à l'identique, sur n'importe quelle machine, les vérifications et la compilation de la CI. Elle part de l'image Flutter `stable` de Cirrus Labs : pour figer une version, passez `--build-arg FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:<version>`.

## Limites

Rien ne compile l'application iOS, qui demande un runner macOS et des certificats Apple. Les workflows utilisent la version stable de Flutter au moment de l'exécution : une fois le premier passage au vert, figez-la avec un numéro de version pour que la CI ne change pas sans prévenir. Aucun pipeline n'a tourné sur GitHub, ils ont seulement passé actionlint et hadolint.
