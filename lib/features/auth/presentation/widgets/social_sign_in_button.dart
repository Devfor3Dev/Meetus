import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/pressable.dart';

enum SocialProvider { google, facebook }

/// Bouton « Continuer avec Google » ou « Continuer avec Facebook ».
///
/// Les logos sont les fichiers officiels de `assets/images/brand/`. Rien n'est
/// redessiné : pour les remplacer, déposez vos fichiers sous les mêmes noms.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  static const double height = 56;

  /// Bleu officiel de Facebook, posé derrière le « f » blanc.
  static const Color _facebookBlue = Color(0xFF1877F2);

  final SocialProvider provider;
  final VoidCallback? onPressed;

  String get _label => switch (provider) {
        SocialProvider.google => 'Continuer avec Google',
        SocialProvider.facebook => 'Continuer avec Facebook',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      onPressed: onPressed,
      semanticLabel: _label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: scheme.outline, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Logo(provider: provider),
                const SizedBox(width: 12),
                Text(_label, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.provider});

  final SocialProvider provider;

  @override
  Widget build(BuildContext context) {
    switch (provider) {
      case SocialProvider.google:
        return Image.asset(AppAssets.googleLogo, width: 24, height: 24);
      case SocialProvider.facebook:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: SocialSignInButton._facebookBlue,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Image.asset(AppAssets.facebookLogo, width: 24, height: 24),
        );
    }
  }
}
