import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class IncomeOutcomeCard extends StatelessWidget {
  const IncomeOutcomeCard({
    super.key,
    required this.incomeNgwee,
    required this.outcomeNgwee,
  });

  final int incomeNgwee;
  final int outcomeNgwee;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      backgroundColor: AppColors.cardDark,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stacked = constraints.maxWidth < 420;

          return Stack(
            children: [
              if (stacked)
                Column(
                  children: [
                    _MetricTile(
                      label: 'Income',
                      amount: formatZmwFromNgwee(incomeNgwee),
                      icon: Icons.trending_up_rounded,
                      accent: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1.5, color: Colors.white54),
                    const SizedBox(height: 16),
                    _MetricTile(
                      label: 'Outcome',
                      amount: formatZmwFromNgwee(outcomeNgwee),
                      icon: Icons.trending_down_rounded,
                      accent: AppColors.danger,
                    ),
                  ],
                ),
              if (!stacked)
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Income',
                        amount: formatZmwFromNgwee(incomeNgwee),
                        icon: Icons.trending_up_rounded,
                        accent: AppColors.success,
                      ),
                    ),
                    Container(width: 1.5, height: 72, color: Colors.white54),
                    Expanded(
                      child: _MetricTile(
                        label: 'Outcome',
                        amount: formatZmwFromNgwee(outcomeNgwee),
                        icon: Icons.trending_down_rounded,
                        accent: AppColors.danger,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
