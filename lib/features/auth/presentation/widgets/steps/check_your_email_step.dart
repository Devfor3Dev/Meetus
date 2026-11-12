import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_link_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';

/// Attente du clic sur le lien de confirmation. Le bouton ouvre la messagerie de
/// l'appareil, et le flux reprend tout seul quand `loveline://verified` arrive.
class CheckYourEmailStep extends ConsumerWidget {
  const CheckYourEmailStep({super.key});

  Future<void> _openMail(BuildContext context, AuthFlowController controller) async {
    final opened = await controller.openMailApp();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ouvrez votre application mail manuellement.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);
    final theme = Theme.of(context);

    return AuthStepScaffold(
      title: 'Vérifiez votre\nboîte mail.',
      subtitle: 'Un lien de confirmation a été envoyé à ${state.email}. '
          'Ouvrez-le pour finaliser votre inscription.',
      errorMessage: state.errorMessage,
      infoMessage: state.infoMessage,
      child: const SizedBox.shrink(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Ouvrir ma messagerie',
            onPressed: () => _openMail(context, controller),
          ),
          const SizedBox(height: 4),
          TextLinkButton(
            label: "Je n'ai rien reçu, renvoyer l'e-mail",
            color: theme.colorScheme.primary,
            onPressed: state.isLoading ? null : controller.resendVerificationEmail,
          ),
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
