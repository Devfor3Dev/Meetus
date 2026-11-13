import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/primary_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authFlowControllerProvider);
    final controller = ref.read(authFlowControllerProvider.notifier);
    final name = state.firstName.trim();

    return AuthStepScaffold(
      title: name.isEmpty ? 'Bienvenue.' : 'Bienvenue,\n$name.',
      subtitle: 'Votre compte est prêt.',
      footer: PrimaryButton(label: 'Continuer', onPressed: controller.finishWelcome),
      child: const SizedBox.shrink(),
    );
  }
}
