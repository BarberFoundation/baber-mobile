import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// One-shot success celebration: two expanding/fading ring pulses plus a
/// small confetti burst, layered behind whatever badge/card the caller
/// centers on top. Purely decorative — wrapped in [IgnorePointer] so it
/// never steals taps from the content underneath.
class RingConfettiOverlay extends StatefulWidget {
  final double size;

  const RingConfettiOverlay({super.key, this.size = 160});

  @override
  State<RingConfettiOverlay> createState() => _RingConfettiOverlayState();
}

class _RingConfettiOverlayState extends State<RingConfettiOverlay> with TickerProviderStateMixin {
  late final AnimationController _ringController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _confettiController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  late final List<_ConfettiSpec> _confetti = List.generate(8, _ConfettiSpec.forIndex);

  @override
  void dispose() {
    _ringController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ConfettiPainter(progress: _confettiController.value, specs: _confetti),
              ),
            ),
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPulsePainter(progress: _ringController.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPulsePainter extends CustomPainter {
  final double progress;

  const _RingPulsePainter({required this.progress});

  void _paintRing(Canvas canvas, Offset center, double t) {
    if (t <= 0) return;
    final radius = t * 70;
    final opacity = (1 - t).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = AppColors.brass.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    _paintRing(canvas, center, progress);
    _paintRing(canvas, center, ((progress - 0.15) / 0.85).clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(covariant _RingPulsePainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiSpec {
  final double angle;
  final double delay;
  final Color color;
  final double rotationSpeed;

  const _ConfettiSpec({
    required this.angle,
    required this.delay,
    required this.color,
    required this.rotationSpeed,
  });

  factory _ConfettiSpec.forIndex(int i) {
    // Seeded per-index (not per-build) so the burst layout is stable across
    // rebuilds within the same widget lifetime, and deterministic in tests.
    final random = math.Random(i);
    const colors = [AppColors.brass, AppColors.barberRed, AppColors.cream];
    return _ConfettiSpec(
      angle: (random.nextDouble() - 0.5) * 2,
      delay: random.nextDouble() * 0.2,
      color: colors[i % colors.length],
      rotationSpeed: 4 + random.nextDouble() * 4,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiSpec> specs;

  const _ConfettiPainter({required this.progress, required this.specs});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final spec in specs) {
      final t = ((progress - spec.delay) / (1 - spec.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final dx = spec.angle * 60 * t;
      final dy = -30 * (1 - t) + 70 * t * t;
      final opacity = (1 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(t * spec.rotationSpeed);
      final paint = Paint()..color = spec.color.withValues(alpha: opacity);
      canvas.drawRect(const Rect.fromLTWH(-3, -5, 6, 10), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
