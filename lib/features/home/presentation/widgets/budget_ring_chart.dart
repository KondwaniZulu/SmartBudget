import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/features/home/domain/budget_category.dart';

class BudgetRingChart extends StatelessWidget {
  const BudgetRingChart({
    super.key,
    required this.categories,
    required this.totalLabel,
  });

  final List<BudgetCategory> categories;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      height: 152,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(152),
            painter: _BudgetRingPainter(categories: categories),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalLabel,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRingPainter extends CustomPainter {
  _BudgetRingPainter({required this.categories});

  final List<BudgetCategory> categories;

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 22;
    final Offset center = size.center(Offset.zero);
    final Rect rect = Rect.fromCircle(
      center: center,
      radius: (size.width - strokeWidth) / 2,
    );
    double startAngle = -math.pi / 2;

    for (final BudgetCategory category in categories) {
      final double sweepAngle = 2 * math.pi * (category.percentage / 100);
      final Paint paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + 0.03;
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetRingPainter oldDelegate) {
    return oldDelegate.categories != categories;
  }
}
