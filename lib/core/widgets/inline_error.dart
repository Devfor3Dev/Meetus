import 'package:flutter/material.dart';

/// Message d'erreur sous un champ ou au-dessus d'un bouton.

/// `liveRegion` fait annoncer le texte par les lecteurs d'écran dès son apparition.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
