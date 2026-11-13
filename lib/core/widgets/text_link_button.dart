import 'package:flutter/material.dart';

import 'pressable.dart';

/// Action secondaire en texte, avec une zone tactile d'au moins 48 px.
class TextLinkButton extends StatelessWidget {
  const TextLinkButton({super.key, required this.label, required this.onPressed, this.color});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Pressable(
      onPressed: onPressed,
      pressedScale: 0.96,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Center(
            widthFactor: 1,
            child: Text(label, style: style?.copyWith(color: color ?? style.color)),
          ),
        ),
      ),
    );
  }
}
