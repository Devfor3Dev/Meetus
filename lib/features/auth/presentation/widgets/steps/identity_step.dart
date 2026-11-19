import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_link_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../../../domain/person_name.dart';
import '../auth_step_scaffold.dart';

/// Prénom et nom. Sert à l'inscription par e-mail, et après une connexion Google
/// ou Facebook quand ces deux informations manquent.
class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(authFlowControllerProvider);
    _firstName = TextEditingController(text: state.firstName);
    _lastName = TextEditingController(text: state.lastName);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    super.dispose();
  }

  String? _validateFirst(String value) => _messageFor(PersonName.validate(value), 'prénom');

  String? _validateLast(String value) => _messageFor(PersonName.validate(value), 'nom');

  String? _messageFor(NameIssue? issue, String field) {
    return switch (issue) {
      null => null,
      NameIssue.empty => 'Entrez votre $field.',
      NameIssue.tooLong => '${PersonName.maxLength} caractères au maximum.',
      NameIssue.invalidCharacters =>
        'Utilisez uniquement des lettres, des espaces, des apostrophes et des tirets.',
    };
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (_validateFirst(_firstName.text) != null) {
      _firstFocus.requestFocus();
      return;
    }
    if (_validateLast(_lastName.text) != null) {
      _lastFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(authFlowControllerProvider.notifier).submitIdentity(
          firstName: _firstName.text,
          lastName: _lastName.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);
    final theme = Theme.of(context);

    return AuthStepScaffold(
      title: 'Comment vous\nappelez-vous\u00a0?',
      subtitle: 'Ces informations servent à créer votre profil.',
      onBack: state.socialIdentity ? null : controller.back,
      errorMessage: state.errorMessage,
      child: Column(
        children: [
          AppTextField(
            controller: _firstName,
            focusNode: _firstFocus,
            label: 'Prénom',
            autofocus: true,
            validator: _validateFirst,
            showErrors: _showErrors,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            onSubmitted: (_) => _lastFocus.requestFocus(),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _lastName,
            focusNode: _lastFocus,
            label: 'Nom',
            validator: _validateLast,
            showErrors: _showErrors,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.familyName],
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: state.isLoading ? 'Enregistrement…' : 'Continuer',
            onPressed: state.isLoading ? null : _submit,
          ),
          if (state.socialIdentity) ...[
            const SizedBox(height: 4),
            TextLinkButton(
              label: 'Utiliser un autre compte',
              color: theme.colorScheme.primary,
              onPressed: state.isLoading ? null : controller.switchAccount,
            ),
          ],
        ],
      ),
    );
  }
}
