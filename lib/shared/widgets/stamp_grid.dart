import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Loyalty stamp-card progress: [total] dots, the first [filled] shown as a
/// brass gradient fill, the rest as an empty outlined ring.
class StampGrid extends StatelessWidget {
  final int filled;
  final int total;

  const StampGrid({super.key, required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final clampedFilled = filled.clamp(0, total);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(total, (i) {
        final isFilled = i < clampedFilled;
        return Container(
          key: ValueKey('stamp-dot-$i'),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isFilled
                ? const LinearGradient(colors: [AppColors.brassDim, AppColors.brass])
                : null,
            border: isFilled ? null : Border.all(color: AppColors.divider, width: 1.5),
          ),
        );
      }),
    );
  }
}
