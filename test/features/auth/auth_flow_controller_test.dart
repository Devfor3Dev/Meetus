import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/features/auth/application/auth_flow_controller.dart';
import 'package:loveline/features/auth/data/auth_repository.dart';
import 'package:loveline/features/auth/domain/auth_exception.dart';
import 'package:loveline/features/auth/domain/auth_user.dart';

import '../../support/test_di.dart';

Future<(ProviderContainer, TestDependencies)> _setUp() async {
  final deps = await setUpTestDependencies(seenOnboarding: true);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return (container, deps);
}

AuthFlowController _controller(ProviderContainer c) =>
    c.read(authFlowControllerProvider.notifier);

AuthFlowState _state(ProviderContainer c) => c.read(authFlowControllerProvider);

void main() {
  group('saisie de l’e-mail', () {
    test('une adresse invalide reste sur l’étape avec un message', () async {
      final (container, deps) = await _setUp();

      await _controller(container).submitEmail('pas-un-mail');

      expect(_state(container).step, AuthStep.emailEntry);
      expect(_state(container).errorMessage, isNotNull);
      expect(deps.repository.loginPasswords, isEmpty);
    });

    test('l’adresse est normalisée puis confirmée', () async {
      final (container, _) = await _setUp();

      await _controller(container).submitEmail('  Awa@Exemple.TG ');

      expect(_state(container).email, 'awa@exemple.tg');
      expect(_state(container).step, AuthStep.confirmEmail);
    });

    test('une erreur réseau s’affiche sans changer d’étape', () async {
      final (container, deps) = await _setUp();
      deps.repository.checkError = AuthException.network();

      await _controller(container).submitEmail('awa@exemple.tg');

      expect(_state(container).step, AuthStep.emailEntry);
      expect(_state(container).errorMessage, AuthException.network().publicMessage);
      expect(_state(container).isLoading, isFalse);
    });
  });

  group('nouveau compte', () {
    test('e-mail, identité, mot de passe, puis attente du lien', () async {
      final (container, deps) = await _setUp();
      final controller = _controller(container);

      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();
      expect(_state(container).step, AuthStep.identity);

      await controller.submitIdentity(firstName: ' Awa ', lastName: 'Koffi');
      expect(_state(container).step, AuthStep.createPassword);
      expect(_state(container).firstName, 'Awa');

      await controller.submitSignupPassword('un-bon-mot-de-passe');
      expect(_state(container).step, AuthStep.checkYourEmail);
      expect(deps.repository.registerCalls, 1);
      expect(deps.deepLinks.isListening, isTrue);
    });

    test('le lien de confirmation connecte avec le mot de passe saisi', () async {
      final (container, deps) = await _setUp();
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();
      await controller.submitIdentity(firstName: 'Awa', lastName: 'Koffi');
      await controller.submitSignupPassword('un-bon-mot-de-passe');

      deps.deepLinks.simulateVerified();
      await Future<void>.delayed(Duration.zero);

      expect(deps.repository.loginPasswords, ['un-bon-mot-de-passe']);
      expect(_state(container).step, AuthStep.welcome);
      expect(deps.deepLinks.isListening, isFalse);
    });

    test('un prénom invalide n’avance pas', () async {
      final (container, _) = await _setUp();
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();

      await controller.submitIdentity(firstName: 'Awa2', lastName: 'Koffi');

      expect(_state(container).step, AuthStep.identity);
      expect(_state(container).errorMessage, isNotNull);
    });

    test('un échec d’inscription affiche le message et reste sur le mot de passe', () async {
      final (container, deps) = await _setUp();
      deps.repository.registerError = const AuthException('Un compte existe déjà avec cet e-mail.');
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();
      await controller.submitIdentity(firstName: 'Awa', lastName: 'Koffi');

      await controller.submitSignupPassword('un-bon-mot-de-passe');

      expect(_state(container).step, AuthStep.createPassword);
      expect(_state(container).errorMessage, 'Un compte existe déjà avec cet e-mail.');
      expect(deps.deepLinks.isListening, isFalse);
    });

    test('le retour suit l’ordre inverse de l’avance', () async {
      final (container, _) = await _setUp();
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();
      await controller.submitIdentity(firstName: 'Awa', lastName: 'Koffi');

      controller.back();
      expect(_state(container).step, AuthStep.identity);
      controller.back();
      expect(_state(container).step, AuthStep.confirmEmail);
      controller.back();
      expect(_state(container).step, AuthStep.emailEntry);
    });
  });

  group('compte existant', () {
    test('un compte vérifié passe par le mot de passe puis la bienvenue', () async {
      final (container, deps) = await _setUp();
      deps.repository.emailCheck = const EmailCheckResult(exists: true, isVerified: true);
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');

      controller.confirmEmailAndProceed();
      expect(_state(container).step, AuthStep.loginPassword);

      await controller.submitLoginPassword('un-bon-mot-de-passe');
      expect(_state(container).step, AuthStep.welcome);
      expect(_state(container).firstName, 'Awa');
    });

    test('un compte non vérifié reprend la vérification, puis demande le mot de passe', () async {
      final (container, deps) = await _setUp();
      deps.repository.emailCheck = const EmailCheckResult(exists: true, isVerified: false);
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');

      controller.confirmEmailAndProceed();
      expect(_state(container).step, AuthStep.checkYourEmail);

      deps.deepLinks.simulateVerified();
      expect(_state(container).step, AuthStep.loginPassword);
      expect(_state(container).infoMessage, isNotNull);
      expect(deps.repository.loginPasswords, isEmpty);
    });

    test('un mot de passe faux affiche le message du serveur', () async {
      final (container, deps) = await _setUp();
      deps.repository.emailCheck = const EmailCheckResult(exists: true, isVerified: true);
      deps.repository.loginError = const AuthException('E-mail ou mot de passe incorrect.');
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();

      await controller.submitLoginPassword('faux');

      expect(_state(container).step, AuthStep.loginPassword);
      expect(_state(container).errorMessage, 'E-mail ou mot de passe incorrect.');
    });

    test('cinq échecs bloquent les essais, sans appeler le serveur une sixième fois', () async {
      final (container, deps) = await _setUp();
      deps.repository.emailCheck = const EmailCheckResult(exists: true, isVerified: true);
      deps.repository.loginError = const AuthException('E-mail ou mot de passe incorrect.');
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');
      controller.confirmEmailAndProceed();

      for (var i = 0; i < 5; i++) {
        await controller.submitLoginPassword('faux');
      }
      expect(_state(container).errorMessage, contains('Trop de tentatives'));

      await controller.submitLoginPassword('faux');
      expect(deps.repository.loginPasswords, hasLength(5));
    });
  });

  group('vérification', () {
    test('renvoyer l’e-mail affiche une confirmation, pas une erreur', () async {
      final (container, deps) = await _setUp();
      final controller = _controller(container);
      await controller.submitEmail('awa@exemple.tg');

      await controller.resendVerificationEmail();

      expect(deps.repository.resendCalls, 1);
      expect(_state(container).infoMessage, isNotNull);
      expect(_state(container).errorMessage, isNull);
    });

    test('ouvrir la messagerie délègue au lanceur', () async {
      final (container, deps) = await _setUp();
      deps.mailLauncher.result = false;

      expect(await _controller(container).openMailApp(), isFalse);
      expect(deps.mailLauncher.calls, 1);
    });
  });

  group('connexion Google et Facebook', () {
    test('un nouveau compte social passe par l’identité puis la bienvenue', () async {
      final (container, deps) = await _setUp();
      final controller = _controller(container);

      await controller.signInWithGoogle();
      expect(_state(container).step, AuthStep.identity);
      expect(_state(container).socialIdentity, isTrue);
      expect(deps.sessionStore.holdInFlow.value, isTrue);

      await controller.submitIdentity(firstName: 'Awa', lastName: 'Koffi');
      expect(deps.repository.saveIdentityCalls, 1);
      expect(_state(container).step, AuthStep.welcome);
    });

    test('un compte social complet va directement à la bienvenue', () async {
      final (container, deps) = await _setUp();
      deps.repository.socialUser = const AuthUser(
        id: 'social-2',
        email: 'awa@exemple.tg',
        firstName: 'Awa',
        lastName: 'Koffi',
        isVerified: true,
        needsIdentity: false,
      );

      await _controller(container).signInWithFacebook();

      expect(_state(container).step, AuthStep.welcome);
    });

    test('fermer la fenêtre du fournisseur n’affiche aucune erreur', () async {
      final (container, deps) = await _setUp();
      deps.repository.socialError = AuthException.cancelled();

      await _controller(container).signInWithGoogle();

      expect(_state(container).errorMessage, isNull);
      expect(_state(container).isLoading, isFalse);
      expect(_state(container).step, AuthStep.emailEntry);
    });

    test('un échec du fournisseur affiche son message', () async {
      final (container, deps) = await _setUp();
      deps.repository.socialError = AuthException.providerUnavailable('Google');

      await _controller(container).signInWithGoogle();

      expect(_state(container).errorMessage, contains('Google'));
    });

    test('une session sans identité reprend à la saisie du nom', () async {
      final deps = await setUpTestDependencies(seenOnboarding: true);
      await deps.sessionStore.setSession(accessToken: 'jeton', needsIdentity: true);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).step, AuthStep.identity);
      expect(_state(container).socialIdentity, isTrue);
    });

    test('changer de compte ferme la session et repart de zéro', () async {
      final (container, deps) = await _setUp();
      final controller = _controller(container);
      await controller.signInWithGoogle();

      await controller.switchAccount();

      expect(deps.repository.logoutCalls, 1);
      expect(_state(container).step, AuthStep.emailEntry);
      expect(deps.sessionStore.isAuthenticated.value, isFalse);
    });
  });

  test('finishWelcome libère le routeur', () async {
    final (container, deps) = await _setUp();
    await deps.sessionStore.setSession(accessToken: 'jeton', needsIdentity: false);

    _controller(container).finishWelcome();

    expect(deps.sessionStore.holdInFlow.value, isFalse);
  });
}
