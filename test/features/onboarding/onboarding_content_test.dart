import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/features/onboarding/domain/onboarding_slide.dart';

void main() {
  group('OnboardingContent', () {
    test('propose quatre diapositives complètes', () {
      expect(OnboardingContent.slides, hasLength(4));
      for (final slide in OnboardingContent.slides) {
        expect(slide.title.trim(), isNotEmpty);
        expect(slide.body.trim(), isNotEmpty);
        expect(slide.imageAsset, isNotEmpty);
      }
    });

    test('les textes évitent tirets longs et flèches', () {
      final forbidden = RegExp('[—–→←]');
      for (final slide in OnboardingContent.slides) {
        expect(forbidden.hasMatch(slide.title), isFalse);
        expect(forbidden.hasMatch(slide.body), isFalse);
      }
    });
  });
}
