import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';

/// Contenu d'une diapositive. On a que la logique ici
@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.imageAsset,
    this.imageAlignment = Alignment.center,
  });

  final String title;
  final String body;
  final String imageAsset;

  /// Partie de la photo à garder visible quand elle est recadrée en plein écran.
  final Alignment imageAlignment;
}

/// Les 4 diapositives affichées au premier lancement.
///
/// Les textes sont des propositions à valider plus tard. Les espaces
/// insécables (écrites \u00a0 dans le code) empêchent « ? » de passer seul à la ligne.
abstract final class OnboardingContent {
  static final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'Vous partagez déjà la même quantine\nEt si vous partagez plus ?',
      body: "il existe peut-être une personne "
          "sur qui tu crush à l'UK. Loveline vous donne la possiblité de l'aborder.",
      imageAsset: AppAssets.onboardingSlide(1),
      imageAlignment: const Alignment(0, -0.3),
    ),
    OnboardingSlide(
      title: 'le feeling ne se discrète\npas. Il se partage',
      body: "Un profil te plait ? Fais le premier pas avec "
          "un like. Si tu es aussi intérresé,\nIl serait temps de faire connaissance.",
      imageAsset: AppAssets.onboardingSlide(1),
      imageAlignment: const Alignment(0, -0.3),
    ),
    OnboardingSlide(
      title: "Mesdames, cette fois,\nc'est à vous de jouer",
      body: "Les femmes vous avez un match ? c'est à vous de démarre la conversation. ",
      imageAsset: AppAssets.onboardingSlide(2),
      imageAlignment: const Alignment(0, -0.3),
    ),
    OnboardingSlide(
      title: 'La prochaine belle histoire\nPourrait commencer ici\u00a0?',
      body: 'Un premier message, des papoteries, Un rendez-vous après les cours '
          'A toi de voir où cette rencontre on peut vous mener',
      imageAsset: AppAssets.onboardingSlide(3),
      imageAlignment: const Alignment(0, -0.3),
    ),
  ];
}
