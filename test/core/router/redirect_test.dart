import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/core/router/app_router.dart';
import 'package:loveline/core/router/routes.dart';

String? _go(
  String location, {
  bool seen = true,
  bool authenticated = false,
  bool needsIdentity = false,
  bool holdInFlow = false,
}) {
  return resolveRedirect(
    location: location,
    hasSeenOnboarding: seen,
    isAuthenticated: authenticated,
    needsIdentity: needsIdentity,
    holdInFlow: holdInFlow,
  );
}

void main() {
  group('visiteur non connecté', () {
    test('voit l’onboarding tant qu’il ne l’a pas vu', () {
      expect(_go(Routes.onboarding, seen: false), isNull);
      expect(_go(Routes.auth, seen: false), Routes.onboarding);
    });

    test('est dirigé vers le flux d’authentification une fois l’onboarding vu', () {
      expect(_go(Routes.onboarding), Routes.auth);
      expect(_go(Routes.auth), isNull);
    });

    test('ne peut pas atteindre l’accueil', () {
      expect(_go(Routes.home), Routes.auth);
    });
  });

  group('utilisateur connecté qui doit encore terminer le flux', () {
    test('reste sur le flux tant que son identité manque', () {
      expect(_go(Routes.auth, authenticated: true, needsIdentity: true), isNull);
      for (final route in [Routes.onboarding, Routes.home]) {
        expect(_go(route, authenticated: true, needsIdentity: true), Routes.auth);
      }
    });

    test('reste sur le flux tant que la bienvenue n’a pas été vue', () {
      expect(_go(Routes.auth, authenticated: true, holdInFlow: true), isNull);
      expect(_go(Routes.home, authenticated: true, holdInFlow: true), Routes.auth);
    });
  });

  group('utilisateur connecté, flux terminé', () {
    test('quitte les écrans d’entrée pour l’accueil', () {
      for (final route in [Routes.onboarding, Routes.auth]) {
        expect(_go(route, authenticated: true), Routes.home);
      }
    });

    test('reste sur l’accueil', () {
      expect(_go(Routes.home, authenticated: true), isNull);
    });
  });
}
