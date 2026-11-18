import 'package:flutter/material.dart';

import '../../../../core/animation/motion.dart';
import '../../../../core/animation/page_offset.dart';
import '../../../../core/theme/palette.dart';
import '../../domain/onboarding_slide.dart';
import 'photo_layer.dart';

/// Une diapositive : photo en parallaxe, voile de lisibilité et texte.
///
/// A partl'entrée du premier écran, les autres ne sont pas animés par le temps. Le
/// fondu du texte et le décalage de la photo sont des fonctions de la
/// position du PageView. Ils suivent donc le doigt à l'identique, peuvent être
/// interrompus à tout moment et ne prennnent pas du tout quand une page est
/// reconstruite.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.slide,
    required this.index,
    required this.pageController,
    required this.intro,
    required this.bottomInset,
  });

  /// Hauteur de la zone de dégradé qui précède le texte.
  static const double _fadeHeight = 120;

  final OnboardingSlide slide;
  final int index;
  final PageController pageController;
  final Animation<double> intro;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([pageController, intro]),
      builder: (context, _) {
        final shift = index - pageOffsetOf(pageController);
        final distance = shift.abs().clamp(0.0, 1.0);
        final textOpacity = (1 - distance * 1.6).clamp(0.0, 1.0);

        final titleIn = const Interval(0.15, 0.75, curve: Motion.out).transform(intro.value);
        final bodyIn = const Interval(0.3, 1, curve: Motion.out).transform(intro.value);
        final rise = reduced ? 0.0 : 16.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            PhotoLayer(
              assetPath: slide.imageAsset,
              alignment: slide.imageAlignment,
              shift: reduced ? 0 : shift,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) => ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(
                        height: _fadeHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Palette.scrimClear, Palette.scrimTop],
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Palette.scrimTop, Palette.scrimBottom],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
                          child: Opacity(
                            opacity: textOpacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Entrance(
                                  progress: titleIn,
                                  rise: rise,
                                  child: Text(
                                    slide.title,
                                    style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _Entrance(
                                  progress: bodyIn,
                                  rise: rise,
                                  child: Text(
                                    slide.body,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withAlpha(0xE0),
                                    ),
                                  ),
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
          ],
        );
      },
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.progress, required this.rise, required this.child});

  final double progress;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(offset: Offset(0, (1 - progress) * rise), child: child),
    );
  }
}
