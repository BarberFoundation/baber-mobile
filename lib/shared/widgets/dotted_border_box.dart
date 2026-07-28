import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dashed-border container for empty states (e.g. "no upcoming appointment").
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;

  const DottedBorderBox({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.color = AppColors.divider,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(borderRadius: borderRadius, color: color),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final double borderRadius;
  final Color color;

  const _DashedRRectPainter({required this.borderRadius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}
