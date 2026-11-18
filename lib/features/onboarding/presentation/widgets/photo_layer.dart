import 'package:flutter/material.dart';

import '../../../../core/theme/palette.dart';

/// Photo plein écran avec effet de parallaxe.
///
/// L'image est plus large que l'écran de 24 %, soit 12 % de chaque côté, et se
/// décale en sens inverse du défilement : elle avance moins vite que le texte,
/// ce qui donne de la profondeur. Le décalage maximal (12 % de la largeur)
/// reste dans la marge,y a pas de bord vide
///
/// Si le fichier est absent, un dégradé bordeaux est ce qu'on voit.
class PhotoLayer extends StatelessWidget {
  const PhotoLayer({
    super.key,
    required this.assetPath,
    required this.alignment,
    required this.shift,
  });

  static const double overscan = 0.12;

  final String assetPath;
  final Alignment alignment;

  /// Position relative de la page : 0 au centre, 1 à droite, -1 à gauche.
  final double shift;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ClipRect(
          child: Transform.translate(
            offset: Offset(-shift * width * overscan, 0),
            child: OverflowBox(
              minWidth: width * (1 + overscan * 2),
              maxWidth: width * (1 + overscan * 2),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: alignment,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => const _FallbackBackdrop(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallbackBackdrop extends StatelessWidget {
  const _FallbackBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.wine, Palette.wineDeep],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.5),
            radius: 0.9,
            colors: [Color(0x55FF436F), Color(0x00FF436F)],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
