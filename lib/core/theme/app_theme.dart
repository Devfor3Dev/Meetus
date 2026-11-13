import 'package:flutter/material.dart';

import './loveline_colors.dart';
import 'palette.dart';
import 'typography.dart';

/// Thèmes clair et sombre. Le sombre est comme sur  les maquettes, le clair c'est
/// la même chose mais sur un fond rosé très pâle plutôt que du blanc pur, pour
/// On pourra changer si c'est pas convenable
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Palette.flame,
      onPrimary: Palette.darkBackground,
      secondary: Palette.superLike,
      onSecondary: Colors.white,
      error: Palette.dangerSoft,
      onError: Palette.darkBackground,
      surface: Palette.darkSurface,
      onSurface: Palette.darkText,
      outline: Palette.darkOutline,
    );
    return _build(
      scheme: scheme,
      background: Palette.darkBackground,
      text: Palette.darkText,
      muted: Palette.darkTextMuted,
      colors: LovelineColors.dark,
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Palette.lightPrimary,
      onPrimary: Colors.white,
      secondary: Palette.superLike,
      onSecondary: Colors.white,
      error: Color(0xFFB00020),
      onError: Colors.white,
      surface: Palette.lightSurface,
      onSurface: Palette.lightText,
      outline: Palette.lightOutline,
    );
    return _build(
      scheme: scheme,
      background: Palette.lightBackground,
      text: Palette.lightText,
      muted: Palette.lightTextMuted,
      colors: LovelineColors.light,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color text,
    required Color muted,
    required LovelineColors colors,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.family,
      textTheme: AppTypography.textTheme(color: text, muted: muted),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
