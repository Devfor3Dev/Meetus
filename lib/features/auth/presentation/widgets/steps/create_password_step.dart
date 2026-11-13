import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../../../domain/password_strength.dart';
import '../../../domain/signup_rules.dart';
import '../auth_step_scaffold.dart';

class CreatePasswordStep extends ConsumerStatefulWidget {
  const CreatePasswordStep({super.key});

  @override
  ConsumerState<CreatePasswordStep> createState() => _CreatePasswordStepState();
}

class _CreatePasswordStepState extends ConsumerState<CreatePasswordStep> {
  final TextEditingController _password = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    // Le champ est vidé avant d'être libéré : le mot de passe ne reste pas dans un
    // contrôleur que le ramasse-miettes n'aurait pas encore collecté.
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (value.length < SignupRules.minPasswordLength) {
      return 'Utilisez au moins ${SignupRules.minPasswordLength} caractères.';
    }
    if (value.length > SignupRules.maxPasswordLength) {
      return '${SignupRules.maxPasswordLength} caractères au maximum.';
    }
    return null;
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (_validate(_password.text) != null) return;
    FocusScope.of(context).unfocus();
    ref.read(authFlowControllerProvider.notifier).submitSignupPassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);

    return AuthStepScaffold(
      title: 'Choisissez un\nmot de passe.',
      subtitle: 'Au moins ${SignupRules.minPasswordLength} caractères.',
      onBack: controller.back,
      errorMessage: state.errorMessage,
      footer: PrimaryButton(
        label: state.isLoading ? 'Création du compte…' : 'Créer mon compte',
        onPressed: state.isLoading ? null : _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _password,
            label: 'Mot de passe',
            autofocus: true,
            obscureText: true,
            maxLength: SignupRules.maxPasswordLength,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            validator: _validate,
            showErrors: _showErrors,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          _StrengthMeter(controller: _password),
        ],
      ),
    );
  }
}

/// Trois segments et un mot. Le mot porte l'information, les segments la renforcent :
/// la couleur n'est jamais le seul indice.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.text.isEmpty) return const SizedBox.shrink();
        final strength = PasswordStrength.evaluate(controller.text);
        return Semantics(
          label: 'Solidité du mot de passe : ${strength.label}',
          excludeSemantics: true,
          child: Row(
            children: [
              for (var i = 1; i <= 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= strength.level ? scheme.primary : scheme.outline.withAlpha(0x59),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const SizedBox(width: 6),
              Text(strength.label, style: theme.textTheme.labelMedium),
            ],
          ),
        );
      },
    );
  }
}
