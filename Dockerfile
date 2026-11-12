# syntax=docker/dockerfile:1

# Image de contrôle et de compilation du mobile. Une application Flutter ne
# s'exécute pas dans un conteneur : celui-ci sert à obtenir, sur n'importe quelle
# machine, exactement les mêmes vérifications et le même APK que la CI.
#
#   docker build --target check -t loveline-mobile:check mobile
#   docker build --target apk   -t loveline-mobile:apk   mobile
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable

# hadolint ignore=DL3006
FROM ${FLUTTER_IMAGE} AS deps
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

FROM deps AS check
COPY . .
RUN flutter pub get \
 && dart format --output=none --set-exit-if-changed . \
 && flutter analyze --no-fatal-infos \
 && flutter test

FROM check AS apk
# Nécessite le dossier android/ (flutter create --platforms=android,ios .).
RUN flutter build apk --debug --dart-define=USE_FAKE_BACKEND=true
