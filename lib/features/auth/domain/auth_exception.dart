/// Exception typée du module auth.
///
/// [publicMessage] est TOUJOURS ce qui est affiché à l'écran :
/// [isCancelled] signale que l'utilisateur a
/// fermé lui-même la fenêtre Google ou Facebook, ce qui n'est pas une erreur en sois à afficher.
class AuthException implements Exception {
  const AuthException(this.publicMessage, {this.internalDetail, this.isCancelled = false});

  final String publicMessage;
  final String? internalDetail;
  final bool isCancelled;

  factory AuthException.network() => const AuthException(
        'Connexion impossible. Vérifiez votre réseau et réessayez.',
      );

  factory AuthException.generic() => const AuthException(
        'Une erreur est survenue. Réessayez dans un instant.',
      );

  factory AuthException.cancelled() => const AuthException('', isCancelled: true);

  factory AuthException.providerUnavailable(String provider) => AuthException(
        "La connexion avec $provider n'est pas disponible sur cet appareil.",
      );

  @override
  String toString() => internalDetail ?? publicMessage;
}
