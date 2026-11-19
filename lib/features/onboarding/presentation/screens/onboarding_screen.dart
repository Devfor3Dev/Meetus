import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/motion.dart';
import '../../../../core/animation/page_offset.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/text_link_button.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/onboarding_slide.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/page_dots.dart';

/// Écran affiché au premier lancement :  4 photos plein écran à faire défiler.
///
/// L'écran est toujours sombre, quel que soit le thème du téléphone, parce que
/// le texte blanc repose sur des photos assombries par un voile.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  /// Place occupée sous le texte par les points, le bouton et la marge basse.
  static const double _controlsHeight = 8 + 28 + PrimaryButton.height + 20;
  static const double _textGap = 28;

  final ThemeData _theme = AppTheme.dark();
  final PageController _pages = PageController();
  late final AnimationController _intro = AnimationController(vsync: this, duration: Motion.intro);
  late final Animation<double> _controlsIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 1, curve: Motion.out),
  );
  bool _introStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introStarted) return;
    _introStarted = true;
    if (Motion.reduced(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _intro.dispose();
    super.dispose();
  }

  int get _currentPage {
    final page = pageOffsetOf(_pages).round();
    return page.clamp(0, OnboardingContent.slides.length - 1);
  }

  Future<void> _goTo(int page) async {
    if (!_pages.hasClients) return;
    if (Motion.reduced(context)) {
      _pages.jumpToPage(page);
      return;
    }
    await _pages.animateToPage(page, duration: Motion.page, curve: Motion.out);
  }

  Future<void> _next() async {
    final last = OnboardingContent.slides.length - 1;
    final current = _currentPage;
    if (current >= last) {
      await _finish();
      return;
    }
    await _goTo(current + 1);
  }

  Future<void> _previous() async {
    final current = _currentPage;
    if (current > 0) await _goTo(current - 1);
  }

  Future<void> _finish() async {
    final done = await ref.read(onboardingControllerProvider.notifier).complete();
    if (done && mounted) context.go(Routes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final slides = OnboardingContent.slides;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final controlsHeight = _controlsHeight + safeBottom;

    return Theme(
      data: _theme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: PopScope(
          canPop: state.page == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _previous();
          },
          child: Scaffold(
            backgroundColor: Palette.darkBackground,
            body: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pages,
                  itemCount: slides.length,
                  onPageChanged: ref.read(onboardingControllerProvider.notifier).onPageChanged,
                  itemBuilder: (context, index) => OnboardingPage(
                    slide: slides[index],
                    index: index,
                    pageController: _pages,
                    intro: _intro,
                    bottomInset: controlsHeight + _textGap,
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: _controlsIn,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                        child: Row(
                          children: [
                            const BrandLogo(),
                            const Spacer(),
                            _SkipButton(visible: !state.isLast, onPressed: _finish),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FadeTransition(
                    opacity: _controlsIn,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + safeBottom),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            container: true,
                            label: 'Page ${state.page + 1} sur ${slides.length}',
                            child: ExcludeSemantics(
                              child: PageDots(controller: _pages, count: slides.length),
                            ),
                          ),
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: state.isLast ? 'Commencer' : 'Continuer',
                            onPressed: state.completing ? null : _next,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: Motion.fast,
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: TextLinkButton(label: 'Passer', color: Colors.white, onPressed: onPressed),
        ),
      ),
    );
  }
}
