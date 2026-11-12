import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_link_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';

class ConfirmEmailStep extends ConsumerWidget {
  const ConfirmEmailStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);
    final theme = Theme.of(context);

    return AuthStepScaffold(
      title: 'Cette adresse\nest correcte\u00a0?',
      onBack: controller.back,
      errorMessage: state.errorMessage,
      child: Text(
        state.email,
        style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onSurface),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(label: 'Oui, continuer', onPressed: controller.confirmEmailAndProceed),
          const SizedBox(height: 4),
          TextLinkButton(
            label: "Modifier l'adresse",
            color: theme.colorScheme.primary,
            onPressed: controller.editEmail,
          ),
        ],
      ),
    );
  }
}
