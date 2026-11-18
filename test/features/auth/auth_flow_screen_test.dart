import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/app.dart';
import 'package:loveline/features/auth/data/auth_repository.dart';
import 'package:loveline/features/auth/domain/auth_exception.dart';

import '../../support/test_di.dart';

const String _emailTitle = 'Entrez votre\nadresse e-mail.';
const String _identityTitle = 'Comment vous\nappelez-vous\u00a0?';

Future<TestDependencies> _pump(WidgetTester tester) async {
  final deps = await setUpTestDependencies(seenOnboarding: true);
  await tester.pumpWidget(const ProviderScope(child: LovelineApp()));
  await tester.pumpAndSettle();
  return deps;
}

Future<void> _enterEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField), email);
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
}

Future<void> _fillIdentity(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'Awa');
  await tester.enterText(find.byType(TextField).at(1), 'Koffi');
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le flux commence par la saisie de l’e-mail, logo en haut, sans icône dessinée',
      (tester) async {
    await _pump(tester);

    expect(find.text(_emailTitle), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Continuer avec Facebook'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('inscription complète par e-mail, du premier écran à l’accueil', (tester) async {
    final deps = await _pump(tester);

    await _enterEmail(tester, 'awa@exemple.tg');
    expect(find.text('awa@exemple.tg'), findsOneWidget);

    await tester.tap(find.text('Oui, continuer'));
    await tester.pumpAndSettle();
    expect(find.text(_identityTitle), findsOneWidget);

    await _fillIdentity(tester);
    expect(find.textContaining('Choisissez un'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'un-bon-mot-de-passe');
    await tester.pump();
    expect(find.text('Solide'), findsOneWidget);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir ma messagerie'), findsOneWidget);
    await tester.tap(find.text('Ouvrir ma messagerie'));
    await tester.pumpAndSettle();
    expect(deps.mailLauncher.calls, 1);

    deps.deepLinks.simulateVerified();
    await tester.pumpAndSettle();
    expect(find.textContaining('Bienvenue'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Awa'), findsOneWidget);
  });

  testWidgets('une adresse invalide affiche l’erreur et n’appelle pas le serveur', (tester) async {
    await _pump(tester);

    await _enterEmail(tester, 'pas-un-mail');

    expect(find.text('Cette adresse e-mail ne semble pas valide.'), findsOneWidget);
    expect(find.text(_emailTitle), findsOneWidget);
  });

  testWidgets('aucune erreur n’apparaît pendant la première frappe', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();

    expect(find.textContaining('ne semble pas valide'), findsNothing);
  });

  testWidgets('un compte existant demande son mot de passe, qu’on peut afficher', (tester) async {
    final deps = await _pump(tester);
    deps.repository.emailCheck = const EmailCheckResult(exists: true, isVerified: true);

    await _enterEmail(tester, 'awa@exemple.tg');
    await tester.tap(find.text('Oui, continuer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Content de'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'secret-123');
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.text('Afficher'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    expect(find.text('Masquer'), findsOneWidget);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bienvenue'), findsOneWidget);
  });

  testWidgets('connexion Google d’un nouveau compte : identité, bienvenue, accueil', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();
    expect(find.text(_identityTitle), findsOneWidget);
    expect(find.text('Retour'), findsNothing);

    await _fillIdentity(tester);
    expect(find.textContaining('Bienvenue'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Awa'), findsOneWidget);
  });

  testWidgets('fermer la fenêtre Google n’affiche aucune erreur', (tester) async {
    final deps = await _pump(tester);
    deps.repository.socialError = AuthException.cancelled();

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();

    expect(find.text(_emailTitle), findsOneWidget);
    expect(find.textContaining('indisponible'), findsNothing);
  });

  testWidgets('le bouton retour système recule d’une étape', (tester) async {
    await _pump(tester);
    await _enterEmail(tester, 'awa@exemple.tg');
    expect(find.text('Oui, continuer'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_emailTitle), findsOneWidget);
  });

  testWidgets('se déconnecter depuis l’accueil ramène au flux', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();
    await _fillIdentity(tester);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text(_emailTitle), findsOneWidget);
  });
}
