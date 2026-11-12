import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/inline_error.dart';
import '../../../../core/widgets/text_link_button.dart';

/// Gabarit commun aux étapes du flux : logo en haut, retour optionnel, titre,
/// sous-titre, contenu qui défile, messages, puis pied de page fixe (le bouton
/// principal) qui remonte avec le clavier.
class AuthStepScaffold extends StatelessWidget {
  const AuthStepScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.footer,
    this.subtitle,
    this.onBack,
    this.errorMessage,
    this.infoMessage,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget footer;
  final VoidCallback? onBack;
  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
            child: Row(
              children: [
                const BrandLogo(),
                const Spacer(),
                if (onBack != null)
                  TextLinkButton(
                    label: 'Retour',
                    color: theme.colorScheme.primary,
                    onPressed: onBack,
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.displayMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 12),
                    Text(subtitle!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorMessage != null) ...[
                  InlineError(message: errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (infoMessage != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(infoMessage!, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 12),
                ],
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
