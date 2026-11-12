import 'package:flutter/material.dart';

import 'palette.dart';

/// Couleurs sémantiques qui ne sont pas gérés par ColorScheme.
///
/// On les lit avec `Theme.of(context).extension<LovelineColors>()!`.
@immutable
class LovelineColors extends ThemeExtension<LovelineColors> {
  const LovelineColors({
    required this.cta,
    required this.onCta,
    required this.accent,
    required this.focusRing,
    required this.superLike,
    required this.online,
  });

  final LinearGradient cta;
  final Color onCta;
  final Color accent;
  final Color focusRing;
  final Color superLike;
  final Color online;

  static const LinearGradient _ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Palette.ctaStart, Palette.ctaEnd],
  );

  static const LovelineColors dark = LovelineColors(
    cta: _ctaGradient,
    onCta: Colors.white,
    accent: Palette.flame,
    focusRing: Colors.white,
    superLike: Palette.superLike,
    online: Palette.online,
  );

  static const LovelineColors light = LovelineColors(
    cta: _ctaGradient,
    onCta: Colors.white,
    accent: Palette.lightPrimary,
    focusRing: Palette.lightText,
    superLike: Palette.superLike,
    online: Palette.online,
  );

  @override
  LovelineColors copyWith({
    LinearGradient? cta,
    Color? onCta,
    Color? accent,
    Color? focusRing,
    Color? superLike,
    Color? online,
  }) {
    return LovelineColors(
      cta: cta ?? this.cta,
      onCta: onCta ?? this.onCta,
      accent: accent ?? this.accent,
      focusRing: focusRing ?? this.focusRing,
      superLike: superLike ?? this.superLike,
      online: online ?? this.online,
    );
  }

  @override
  LovelineColors lerp(ThemeExtension<LovelineColors>? other, double t) {
    if (other is! LovelineColors) return this;
    return LovelineColors(
      cta: LinearGradient.lerp(cta, other.cta, t) ?? cta,
      onCta: Color.lerp(onCta, other.onCta, t) ?? onCta,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      focusRing: Color.lerp(focusRing, other.focusRing, t) ?? focusRing,
      superLike: Color.lerp(superLike, other.superLike, t) ?? superLike,
      online: Color.lerp(online, other.online, t) ?? online,
    );
  }
}
