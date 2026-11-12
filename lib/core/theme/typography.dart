import 'package:flutter/material.dart';

/// Échelle typographique de Loveline.
///
/// Les maquettes utilisent une famille géométrique aux angles carrés et aux
/// courbes arrondies. Exo 2 (licence OFL) est ce qui ressemble le plus à ça. Les graisses
/// sont des fichiers statiques, pour éviter tout
/// épaississement artificiel selon la plateforme.
abstract final class AppTypography {
  static const String family = 'Exo2';

  static TextTheme textTheme({required Color color, required Color muted}) {
    TextStyle style(double size, FontWeight weight, double height, Color c, {double spacing = 0}) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: c,
      );
    }

    return TextTheme(
      displayLarge: style(36, FontWeight.w700, 1.14, color, spacing: -0.5),

      displayMedium: style(30, FontWeight.w700, 1.17, color, spacing: -0.3),

      headlineMedium: style(24, FontWeight.w600, 1.25, color),

      titleLarge: style(20, FontWeight.w600, 1.3, color),

      titleMedium: style(17, FontWeight.w600, 1.3, color, spacing: 0.1),

      bodyLarge: style(16, FontWeight.w400, 1.5, muted),

      bodyMedium: style(14, FontWeight.w400, 1.45, muted),

      labelLarge: style(15, FontWeight.w600, 1.3, color, spacing: 0.1),

      labelMedium: style(13, FontWeight.w500, 1.3, muted),
    );
  }
}
