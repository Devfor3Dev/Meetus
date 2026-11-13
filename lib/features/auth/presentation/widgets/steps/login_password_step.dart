import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';

class LoginPasswordStep extends ConsumerStatefulWidget {
  const LoginPasswordStep({super.key});

  @override
  ConsumerState<LoginPasswordStep> createState() => _LoginPasswordStepState();
}

class _LoginPasswordStepState extends ConsumerState<LoginPasswordStep> {
  final TextEditingController _password = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  String? _validate(String value) => value.isEmpty ? 'Entrez votre mot de passe.' : null;

  void _submit() {
    setState(() => _showErrors = true);
    if (_validate(_password.text) != null) return;
    FocusScope.of(context).unfocus();
    ref.read(authFlowControllerProvider.notifier).submitLoginPassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);

    return AuthStepScaffold(
      title: 'Content de\nvous revoir.',
      subtitle: 'Entrez le mot de passe de ${state.email}.',
      onBack: controller.back,
      errorMessage: state.errorMessage,
      infoMessage: state.infoMessage,
      child: AppTextField(
        controller: _password,
        label: 'Mot de passe',
        autofocus: true,
        obscureText: true,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        validator: _validate,
        showErrors: _showErrors,
        onSubmitted: (_) => _submit(),
      ),
      footer: PrimaryButton(
        label: state.isLoading ? 'Connexion…' : 'Se connecter',
        onPressed: state.isLoading ? null : _submit,
      ),
    );
  }
}
