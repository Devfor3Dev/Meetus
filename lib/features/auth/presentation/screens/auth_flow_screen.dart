import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/motion.dart';
import '../../application/auth_flow_controller.dart';
import '../widgets/steps/check_your_email_step.dart';
import '../widgets/steps/confirm_email_step.dart';
import '../widgets/steps/create_password_step.dart';
import '../widgets/steps/email_entry_step.dart';
import '../widgets/steps/identity_step.dart';
import '../widgets/steps/login_password_step.dart';
import '../widgets/steps/welcome_step.dart';

/// Une seule route héberge toutes les étapes, comme dans l'application de bus. Le
/// bouton retour système recule d'une étape au lieu de quitter le flux.
class AuthFlowScreen extends ConsumerStatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  ConsumerState<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends ConsumerState<AuthFlowScreen> {
  /// Ordre d'avancement, pour savoir dans quel sens glisse une transition. Il
  /// n'est pas celui de l'énumération : la connexion se situe après la vérification.
  static const Map<AuthStep, int> _rank = {
    AuthStep.emailEntry: 0,
    AuthStep.confirmEmail: 1,
    AuthStep.identity: 2,
    AuthStep.createPassword: 3,
    AuthStep.checkYourEmail: 5,
    AuthStep.loginPassword: 6,
    AuthStep.welcome: 7,
  };

  AuthStep _previous = AuthStep.emailEntry;
  bool _forward = true;

  Widget _stepFor(AuthStep step) {
    return switch (step) {
      AuthStep.emailEntry => const EmailEntryStep(),
      AuthStep.confirmEmail => const ConfirmEmailStep(),
      AuthStep.loginPassword => const LoginPasswordStep(),
      AuthStep.identity => const IdentityStep(),
      AuthStep.createPassword => const CreatePasswordStep(),
      AuthStep.checkYourEmail => const CheckYourEmailStep(),
      AuthStep.welcome => const WelcomeStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(authFlowControllerProvider.select((state) => state.step));
    if (step != _previous) {
      _forward = _rank[step]! >= _rank[_previous]!;
      _previous = step;
    }
    final direction = _forward ? 1.0 : -1.0;

    return PopScope(
      canPop: step == AuthStep.emailEntry,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(authFlowControllerProvider.notifier).back();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 260),
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey<AuthStep>(step);
            final eased = animation.drive(CurveTween(curve: Motion.out));
            final slide = eased.drive(
              Tween<Offset>(
                begin: Offset((incoming ? direction : -direction) * 0.06, 0),
                end: Offset.zero,
              ),
            );
            return IgnorePointer(
              ignoring: !incoming,
              child: FadeTransition(
                opacity: eased,
                child: SlideTransition(position: slide, child: child),
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey<AuthStep>(step), child: _stepFor(step)),
        ),
      ),
    );
  }
}
