import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/app.dart';

import '../../support/test_di.dart';

const String _emailTitle = 'Entrez votre\nadresse e-mail.';

Future<TestDependencies> _pumpApp(WidgetTester tester, {bool seen = false}) async {
  final deps = await setUpTestDependencies(seenOnboarding: seen);
  await tester.pumpWidget(const ProviderScope(child: LovelineApp()));
  await tester.pumpAndSettle();
  return deps;
}

void main() {
  testWidgets('affiche la première diapositive au premier lancement', (tester) async {
    await _pumpApp(tester);

    expect(find.textContaining('tout le monde'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
  });

  testWidgets('saute l’onboarding s’il a déjà été vu', (tester) async {
    await _pumpApp(tester, seen: true);

    expect(find.textContaining('tout le monde'), findsNothing);
    expect(find.text(_emailTitle), findsOneWidget);
  });

  testWidgets('Continuer mène jusqu’à Commencer puis à l’écran de connexion', (tester) async {
    final deps = await _pumpApp(tester);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('vraie rencontre'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Commencer'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(deps.preferences.hasSeenOnboarding, isTrue);
    expect(find.text(_emailTitle), findsOneWidget);
  });

  testWidgets('Passer termine l’onboarding sans parcourir les pages', (tester) async {
    final deps = await _pumpApp(tester);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(deps.preferences.hasSeenOnboarding, isTrue);
    expect(find.text(_emailTitle), findsOneWidget);
  });

  testWidgets('un balayage change de page', (tester) async {
    await _pumpApp(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.textContaining('vraie rencontre'), findsOneWidget);
  });

  testWidgets('le bouton retour revient à la page précédente', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.textContaining('tout le monde'), findsOneWidget);
  });
}
