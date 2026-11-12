import 'package:flutter/material.dart';

import '../animation/motion.dart';

/// Apparition: fondu et légère montée, avec un délai optionnel pour
/// échelonner plusieurs éléments. Avec « réduire les animations », l'élément
/// apparaît tel quel.
class FadeInUp extends StatelessWidget {
  const FadeInUp({super.key, required this.child, this.delay = Duration.zero, this.rise = 14});

  static const Duration _duration = Duration(milliseconds: 420);

  final Widget child;
  final Duration delay;
  final double rise;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;

    final total = delay + _duration;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Motion.out),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * rise), child: child),
      ),
    );
  }
}
