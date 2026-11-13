import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/auth_flow_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../di/injection.dart';
import '../storage/auth_session_store.dart';
import '../storage/local_preferences_service.dart';
import '../widgets/text_link_button.dart';
import 'routes.dart';

/// Construit le routeur.
/// la navigation
/// qui viens de l'état de session et de l'onboarding, et le routeur se réévalue à
/// chaque changement.
GoRouter buildAppRouter() {
  final session = getIt<AuthSessionStore>();

  return GoRouter(
    initialLocation: Routes.onboarding,
    refreshListenable: Listenable.merge([
      session.isAuthenticated,
      session.needsIdentity,
      session.holdInFlow,
    ]),
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      hasSeenOnboarding: getIt<LocalPreferencesService>().hasSeenOnboarding,
      isAuthenticated: session.isAuthenticated.value,
      needsIdentity: session.needsIdentity.value,
      holdInFlow: session.holdInFlow.value,
    ),
    routes: [
      GoRoute(path: Routes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: Routes.auth, builder: (context, state) => const AuthFlowScreen()),
      GoRoute(path: Routes.home, builder: (context, state) => const _HomePlaceholder()),
    ],
  );
}

/// Règle de redirection, séparée du routeur pour être testée sans interface.
/// Retourne null quand l'utilisateur est déjà au bon endroit.

String? resolveRedirect({
  required String location,
  required bool hasSeenOnboarding,
  required bool isAuthenticated,
  required bool needsIdentity,
  required bool holdInFlow,
}) {
  if (isAuthenticated) {
    if (needsIdentity || holdInFlow) {
      return location == Routes.auth ? null : Routes.auth;
    }
    return (location == Routes.onboarding || location == Routes.auth) ? Routes.home : null;
  }

  if (!hasSeenOnboarding) {
    return location == Routes.onboarding ? null : Routes.onboarding;
  }
  return location == Routes.auth ? null : Routes.auth;
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    final name = getIt<AuthSessionStore>().currentUser.value?.firstName;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name == null ? "Accueil à brancher par l'équipe" : 'Bonjour $name',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextLinkButton(
                  label: 'Se déconnecter',
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => getIt<AuthRepository>().logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
