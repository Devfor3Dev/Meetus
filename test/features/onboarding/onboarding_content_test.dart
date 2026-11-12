import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/core/constants/app_assets.dart';
import 'package:loveline/features/onboarding/domain/onboarding_slide.dart';

void main() {
  group('OnboardingContent', () {
    test('propose trois diapositives complètes', () {
      expect(OnboardingContent.slides, hasLength(3));
      for (final slide in OnboardingContent.slides) {
        expect(slide.title.trim(), isNotEmpty);
        expect(slide.body.trim(), isNotEmpty);
      }
    });

    test('chaque diapositive pointe vers la photo numérotée correspondante', () {
      for (var i = 0; i < OnboardingContent.slides.length; i++) {
        expect(OnboardingContent.slides[i].imageAsset, AppAssets.onboardingSlide(i + 1));
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
