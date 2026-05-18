import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class SpendingTrendCard extends StatelessWidget {
  const SpendingTrendCard({
    super.key,
    required this.series,
    required this.currentIncomeNgwee,
    required this.currentExpenseNgwee,
  });

  final List<MonthlyPoint> series;
  final int currentIncomeNgwee;
  final int currentExpenseNgwee;

  @override
  Widget build(BuildContext context) {
    final int maxValue = series.isEmpty
        ? 1
        : series
              .map((e) => e.expenseNgwee)
              .fold<int>(1, (a, b) => a > b ? a : b);

    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trend',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: series
                  .map(
                    (point) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: maxValue <= 0
                                  ? 4
                                  : (88 * (point.expenseNgwee / maxValue))
                                        .clamp(4, 88)
                                        .toDouble(),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              point.label,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Income',
                  value: formatZmwFromNgwee(currentIncomeNgwee),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Expense',
                  value: formatZmwFromNgwee(currentExpenseNgwee),
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MonthlyPoint {
  const MonthlyPoint({required this.label, required this.expenseNgwee});

  final String label;
  final int expenseNgwee;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
