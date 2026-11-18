/// Chemins des ressources embarquées.
abstract final class AppAssets {
  static const String _onboardingDir = 'assets/images/onboarding';

  /// Photo plein écran d'une diapositive d'onboarding, numérotée à partir de 1.
  /// dans le cas  où  le fichier est absent, l'écran affiche un fond dégradé de remplacement.
  static String onboardingSlide(int number) => '$_onboardingDir/slide_$number.jpg';

  /// Logo de loveline  : `assets/images/brand/logo.png`.
  /// Voir BrandLogo
  static const String brandLogo = 'assets/images/brand/logo.png';

  /// Logos officiels des fournisseurs de connexion
  static const String googleLogo = 'assets/images/brand/google.png';
  static const String facebookLogo = 'assets/images/brand/facebook.png';

  const AppAssets._();
}

/// Clés de stockage local. Les secrets vont dans [SecureStorageService],
/// les indicateurs d'interface dans [LocalPreferencesService].
abstract final class AppStorageKeys {
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String secureAuthToken = 'secure_auth_token';
  static const String secureNeedsIdentity = 'secure_needs_identity';

  const AppStorageKeys._();
}
