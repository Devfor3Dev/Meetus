import 'package:flutter/material.dart';

import '../../../../core/animation/page_offset.dart';

/// Indicateur de page dont le point actif s'étire en suivant le doigt.
///
/// Tout est dessiné dans un seul CustomPaint qui se redessine à chaque
/// mouvement du PageController, sans reconstruire de widgets ni changer la
/// mise en page. La largeur totale reste constante : la somme des étirements
/// vaut toujours un point actif.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.controller,
    required this.count,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x8CFFFFFF),
  });

  static const double _dot = 8;
  static const double _gap = 8;
  static const double _stretch = 20;

  final PageController controller;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final width = count * _dot + (count - 1) * _gap + _stretch;
    return CustomPaint(
      size: Size(width, _dot),
      painter: _DotsPainter(
        controller: controller,
        count: count,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({
    required this.controller,
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
  }) : super(repaint: controller);

  final PageController controller;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final page = pageOffsetOf(controller);
    final paint = Paint();
    var x = 0.0;
    for (var i = 0; i < count; i++) {
      final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
      final width = PageDots._dot + PageDots._stretch * t;
      paint.color = Color.lerp(inactiveColor, activeColor, t) ?? inactiveColor;
      canvas.drawRRect(
        RRect.fromLTRBR(x, 0, x + width, PageDots._dot, const Radius.circular(PageDots._dot / 2)),
        paint,
      );
      x += width + PageDots._gap;
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) {
    return old.count != count ||
        old.activeColor != activeColor ||
        old.inactiveColor != inactiveColor ||
        old.controller != controller;
  }
}
