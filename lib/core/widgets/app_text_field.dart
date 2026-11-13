import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inline_error.dart';

/// Champ de texte de Loveline : libellé fixe au-dessus, contour qui passe le
/// contraste 3 sur 1, erreur en texte.
///

/// L'erreur n'apparaît que quand on quitte le champ ou qu'on soumet le formulaire
/// ([showErrors]). Ensuite elle se met à jour
/// en même temps, pour disparaître dès que la saisie devient correcte.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.validator,
    this.showErrors = false,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final String? Function(String value)? validator;
  final bool showErrors;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownFocus;
  bool _touched = false;
  late bool _obscured = widget.obscureText;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && !_touched) setState(() => _touched = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final error = (widget.showErrors || _touched)
            ? widget.validator?.call(widget.controller.text)
            : null;

        OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color, width: width),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              obscureText: _obscured,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              autofillHints: widget.autofillHints,
              onSubmitted: widget.onSubmitted,
              // Pas de suggestions ni de correction sur un mot de passe : un clavier tiers
              // mal configuré pourrait les journaliser.
              enableSuggestions: !widget.obscureText,
              autocorrect: !widget.obscureText,
              inputFormatters:
                  widget.maxLength != null ? [LengthLimitingTextInputFormatter(widget.maxLength)] : null,
              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: InputDecoration(
                filled: true,
                fillColor: scheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: border(error == null ? scheme.outline : scheme.error, 1.5),
                focusedBorder: border(error == null ? scheme.primary : scheme.error, 2),
                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: widget.obscureText
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _VisibilityToggle(
                          obscured: _obscured,
                          onPressed: () => setState(() => _obscured = !_obscured),
                        ),
                      )
                    : null,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              InlineError(message: error),
            ],
          ],
        );
      },
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: theme.colorScheme.primary,
        textStyle: theme.textTheme.labelLarge,
      ),
      child: Text(obscured ? 'Afficher' : 'Masquer'),
    );
  }
}
