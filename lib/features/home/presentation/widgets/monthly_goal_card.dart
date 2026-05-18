import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class MonthlyGoalCard extends StatelessWidget {
  const MonthlyGoalCard({
    super.key,
    required this.monthlyBudgetNgwee,
    required this.spentAmountNgwee,
  });

  final int monthlyBudgetNgwee;
  final int spentAmountNgwee;

  @override
  Widget build(BuildContext context) {
    final bool hasBudget = monthlyBudgetNgwee > 0;
    final double ratio = monthlyBudgetNgwee <= 0
        ? 0
        : (spentAmountNgwee / monthlyBudgetNgwee).clamp(0.0, 1.0);
    final int leftToSpendNgwee = (monthlyBudgetNgwee - spentAmountNgwee).clamp(
      0,
      monthlyBudgetNgwee,
    );

    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Goal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasBudget
                ? '${formatZmwFromNgwee(spentAmountNgwee)} of ${formatZmwFromNgwee(monthlyBudgetNgwee)} used'
                : 'No budget limit set yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFFF0EBE3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentOrange,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(
                label: 'Left to spend',
                value: formatZmwFromNgwee(leftToSpendNgwee),
                icon: Icons.savings_outlined,
                iconColor: AppColors.success,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Usage',
                value: hasBudget
                    ? '${(ratio * 100).toStringAsFixed(0)}%'
                    : '0%',
                icon: Icons.insights_outlined,
                iconColor: AppColors.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4ED),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
