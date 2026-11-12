import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/local_preferences_service.dart';
import '../domain/onboarding_slide.dart';

@immutable
class OnboardingState {
  const OnboardingState({this.page = 0, this.completing = false});

  final int page;
  final bool completing;

  /// Déduit de la page courante  pour ne eviter qu'ils  se désynchronisent
  bool get isLast => page >= OnboardingContent.slides.length - 1;

  OnboardingState copyWith({int? page, bool? completing}) {
    return OnboardingState(
      page: page ?? this.page,
      completing: completing ?? this.completing,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void onPageChanged(int page) {
    if (page == state.page) return;
    state = state.copyWith(page: page);
  }

  /// Enregistre que l'onboarding a été vu. Retourne false si une fin est déjà
  /// en cours, ce qui neutralise les doubles appuis sur « Commencer ».
  ///
  /// En cas d'echec d'écriture on renvoi
  /// l'onboarding au prochain lancement.
  Future<bool> complete() async {
    if (state.completing) return false;
    state = state.copyWith(completing: true);
    try {
      await getIt<LocalPreferencesService>().setOnboardingSeen();
    } catch (error) {
      debugPrint("Impossible d'enregistrer la fin de l'onboarding : $error");
    }
    return true;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);
