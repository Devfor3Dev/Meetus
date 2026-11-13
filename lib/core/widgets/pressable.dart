import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/motion.dart';
import '../theme/loveline_colors.dart';

/// Enveloppe tactile utilisé par tous les boutons.
///
/// Le retour visuel démarre dès le toucher et non au relâchement, sinon
/// l'interaction paraît en retard. Le relâchement est un peu plus lent que
/// l'appui. Avec « réduire les animations », le rétrécissement est remplacé
/// par une légère baisse d'opacité. Le focus clavier est visible, et la zone
/// tactile est celle de l'enfant : les boutons de Loveline font au moins 48 px.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.pressedScale = 0.97,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double pressedScale;
  final BorderRadius borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduced = Motion.reduced(context);
    final ring = Theme.of(context).extension<LovelineColors>()?.focusRing ?? Colors.white;

    final visual = AnimatedScale(
      scale: _pressed && !reduced ? widget.pressedScale : 1,
      duration: _pressed ? Motion.fast : Motion.release,
      curve: Motion.out,
      child: AnimatedOpacity(
        opacity: _pressed && reduced ? 0.8 : 1,
        duration: Motion.fast,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(color: _focused ? ring : Colors.transparent, width: 2.5),
          ),
          child: widget.child,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: visual,
        ),
      ),
    );
  }
}
