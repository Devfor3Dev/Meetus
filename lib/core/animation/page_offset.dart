import 'package:flutter/widgets.dart';

/// Position fractionnaire courante d'un PageView
///
/// ici `PageController.page` lève une assertion tant qu'il n'y a pas eu de mise en page.
/// On retourne alors la page initiale, ce qui évite un écran rouge
/// au premier build.
double pageOffsetOf(PageController controller) {
  if (!controller.hasClients) return controller.initialPage.toDouble();
  final position = controller.position;
  if (!position.hasPixels || !position.hasContentDimensions) {
    return controller.initialPage.toDouble();
  }
  return controller.page ?? controller.initialPage.toDouble();
}
