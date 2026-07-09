import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The signature mark: a thin diagonal barber-pole stripe.
/// Used sparingly — under headers, atop the hero card, as a section rule.
class StripeBar extends StatelessWidget {
  final double height;

  const StripeBar({super.key, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StripePainter(),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  static const _stripeWidth = 14.0;
  static const _colors = [AppColors.barberRed, AppColors.cream, AppColors.brass];

  @override
  void paint(Canvas canvas, Size size) {
    final diagonal = size.height;
    var x = -diagonal;
    var i = 0;
    while (x < size.width + diagonal) {
      final paint = Paint()..color = _colors[i % _colors.length];
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + diagonal, 0)
        ..lineTo(x + diagonal + _stripeWidth, 0)
        ..lineTo(x + _stripeWidth, size.height)
        ..close();
      canvas.drawPath(path, paint);
      x += _stripeWidth;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
