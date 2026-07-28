import 'package:flutter/material.dart';
import 'ring_confetti_overlay.dart';

/// Success badge: [child] pops in with an overshoot/bounce scale while a
/// [RingConfettiOverlay] plays behind it. One-shot — plays once on mount.
class CelebrationBadge extends StatefulWidget {
  final Widget child;
  final double overlaySize;

  const CelebrationBadge({super.key, required this.child, this.overlaySize = 160});

  @override
  State<CelebrationBadge> createState() => _CelebrationBadgeState();
}

class _CelebrationBadgeState extends State<CelebrationBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..forward();

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.overlaySize,
      height: widget.overlaySize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RingConfettiOverlay(size: widget.overlaySize),
          ScaleTransition(scale: _scale, child: widget.child),
        ],
      ),
    );
  }
}
