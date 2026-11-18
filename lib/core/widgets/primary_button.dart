import 'package:flutter/material.dart';

import '../theme/loveline_colors.dart';
import 'pressable.dart';

/// Bouton d'action principal : dégradé de la marque, texte blanc.
///
/// Le dégradé est  plus profond que la flamme des maquettes,
/// parce que du blanc sur la flamme n'atteint que 3,34 sur 1 de contraste.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LovelineColors>()!;
    final enabled = onPressed != null;

    return Pressable(
      onPressed: onPressed,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? colors.cta : null,
            color: enabled ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: enabled ? colors.onCta : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
