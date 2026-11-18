import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../../../domain/signup_rules.dart';
import '../auth_step_scaffold.dart';
import '../social_sign_in_button.dart';

class EmailEntryStep extends ConsumerStatefulWidget {
  const EmailEntryStep({super.key});

  @override
  ConsumerState<EmailEntryStep> createState() => _EmailEntryStepState();
}

class _EmailEntryStepState extends ConsumerState<EmailEntryStep> {
  late final TextEditingController _email;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: ref.read(authFlowControllerProvider).email);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (value.trim().isEmpty) return 'Entrez votre adresse e-mail.';
    if (!SignupRules.isValidEmail(SignupRules.normalizeEmail(value))) {
      return 'Cette adresse e-mail ne semble pas valide.';
    }
    return null;
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (_validate(_email.text) != null) return;
    ref.read(authFlowControllerProvider.notifier).submitEmail(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);
    final theme = Theme.of(context);

    return AuthStepScaffold(
      title: 'Entrez votre\nadresse e-mail.',
      subtitle: 'Elle nous sert à créer votre compte ou à vous reconnecter.',
      errorMessage: state.errorMessage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _email,
            label: 'E-mail',
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: _validate,
            showErrors: _showErrors,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 32),
          Center(child: Text('ou', style: theme.textTheme.bodyMedium)),
          const SizedBox(height: 16),
          SocialSignInButton(
            provider: SocialProvider.google,
            onPressed: state.isLoading ? null : controller.signInWithGoogle,
          ),
          const SizedBox(height: 12),
          SocialSignInButton(
            provider: SocialProvider.facebook,
            onPressed: state.isLoading ? null : controller.signInWithFacebook,
          ),
        ],
      ),
      footer: PrimaryButton(
        label: state.isLoading ? 'Vérification…' : 'Continuer',
        onPressed: state.isLoading ? null : _submit,
      ),
    );
  }
}
