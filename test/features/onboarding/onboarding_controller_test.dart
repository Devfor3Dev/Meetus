import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/features/onboarding/application/onboarding_controller.dart';
import 'package:loveline/features/onboarding/domain/onboarding_slide.dart';

import '../../support/test_di.dart';

void main() {
  test('la dernière page est déduite de la page courante', () async {
    await setUpTestDependencies();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(onboardingControllerProvider).isLast, isFalse);
    final lastIndex = OnboardingContent.slides.length - 1;
    container.read(onboardingControllerProvider.notifier).onPageChanged(lastIndex);
    expect(container.read(onboardingControllerProvider).isLast, isTrue);
  });

  test('complete enregistre la fin et refuse un second appel', () async {
    final deps = await setUpTestDependencies();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(onboardingControllerProvider.notifier);

    expect(await controller.complete(), isTrue);
    expect(await controller.complete(), isFalse);
    expect(deps.preferences.hasSeenOnboarding, isTrue);
  });
}
