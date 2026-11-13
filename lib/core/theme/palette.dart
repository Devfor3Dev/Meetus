import 'package:flutter/painting.dart';

/// Couleurs brutes de Loveline.
///
/// Les teintes de la marque viennent des maquettes de référence.
/// Mais par contre les valeurs du mode clair sont dérivées de la même famille et leur
/// contraste a été calculé avec la formule WCAG
/// (voir README, section Contrastes).
abstract final class Palette {
  /// Fond bordeaux des maquettes. Sert de base aux dégradés de remplacement.
  static const Color wine = Color(0xFFA01A3D);
  static const Color wineDeep = Color(0xFF2A0712);

  /// Dégradé de la flamme. Trop clair pour porter du texte blanc (3,34 sur 1),
  /// il reste réservé aux icônes et aux accents sur fond sombre.
  static const Color flame = Color(0xFFFF436F);
  static const Color flameEnd = Color(0xFFFF317D);

  /// Dégradé des boutons principaux, assez profond pour du texte blanc (4,67 et 5,96).
  static const Color ctaStart = Color(0xFFE11D52);
  static const Color ctaEnd = Color(0xFFC2184A);

  static const Color superLike = Color(0xFF0595EC);
  static const Color online = Color(0xFF52FF8E);
  static const Color danger = Color(0xFFFF0049);

  /// Rouge d'erreur pour le texte sur fond sombre (7,23 sur noir, 6,26 sur les cartes).
  static const Color dangerSoft = Color(0xFFFF6B8A);

  static const Color darkBackground = Color(0xFF0B0B0C);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextMuted = Color(0xFFB8B0B3);
  static const Color darkOutline = Color(0xFF8A8084);

  static const Color lightBackground = Color(0xFFFFF7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2B0A14);
  static const Color lightTextMuted = Color(0xFF6B4A55);
  static const Color lightOutline = Color(0xFF8C6B77);
  static const Color lightPrimary = Color(0xFFC2184A);

  /// Voile  sur les photos : un noir légèrement teinté de bordeaux, transparent
  /// en haut du dégradé, à 72 % au début du texte et à 90 % au pied de l'écran.
  static const Color scrimClear = Color(0x001A0509);
  static const Color scrimTop = Color(0xB81A0509);
  static const Color scrimBottom = Color(0xE61A0509);
}
