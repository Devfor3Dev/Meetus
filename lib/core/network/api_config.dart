import 'package:flutter/foundation.dart';

/// Configuration réseau et d'authentification,
/// `--dart-define`.
///
///  lancement sur émulateur Android :
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
///
/// Attention! n'écrivez jamais l'identifiant de google dans un widget
abstract final class ApiConfig {
  /// 10.0.2.2 est l'alias de « localhost de la machine hôte » dans l'émulateur
  /// Android. Sur un vrai tel, passez l'adresse de votre machine ou un tunnel.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Identifiant client OAuth de type « Web » créé dans Google Cloud. C'est lui,
  /// et non l'identifiant Android, qui donne un jeton d'identité vérifiable par l'API.
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);
 /// Pour éviter que les jetons ne partes en clair, un build release plantera avec une URL en http
  /// . En développement, il n'y aura qu'un simple avertissement.
  static void assertSecureInRelease() {
    final isSecure = baseUrl.startsWith('https://');
    if (kReleaseMode && !isSecure) {
      throw StateError(
        'Build de production avec une URL API non chiffrée ($baseUrl). '
        'Relancez avec --dart-define=API_BASE_URL=https://...',
      );
    }
    if (!kReleaseMode && !isSecure) {
      debugPrint('ApiConfig : URL API non chiffrée ($baseUrl), acceptable en développement.');
    }
  }

  const ApiConfig._();
}
