import 'package:flutter/widgets.dart';

/// Durées et courbes utilisée dans toute l'application
///
/// Une interface se sent vive quand la réponse démarre immédiatement et
/// ralentit en fin de course. Les courbes d'entrée sont donc toutes des
/// ease-out marqués.
abstract final class Motion {
  static const Curve out = Cubic(0.23, 1, 0.32, 1);

  /// Retour tactile à l'appui.
  static const Duration fast = Duration(milliseconds: 120);

  /// Relâchement d'un appui, c'est plus lent que l'appui lui-même et c'est fait exprêt
  static const Duration release = Duration(milliseconds: 180);

  /// Changement de page.
  static const Duration page = Duration(milliseconds: 300);

  /// Entrée unique du premier écran.
  static const Duration intro = Duration(milliseconds: 700);

  /// deviens Vrai quand l'utilisateur a demandé de réduire les animations.
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}
