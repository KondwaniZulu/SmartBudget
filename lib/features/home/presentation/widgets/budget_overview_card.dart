import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/domain/budget_category.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/budget_ring_chart.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({super.key, required this.categories});

  final List<BudgetCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget Overview',
                  style: Theme.of(context).textTheme.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Show All',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stacked = constraints.maxWidth < 520;
              final Widget chart = BudgetRingChart(
                categories: categories,
                totalLabel: _totalLabel(categories),
              );
              final Widget legend = Expanded(
                child: Column(
                  children: categories
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _LegendTile(category: category),
                        ),
                      )
                      .toList(),
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    chart,
                    const SizedBox(height: 18),
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _LegendTile(category: category),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [chart, const SizedBox(width: 24), legend],
              );
            },
          ),
        ],
      ),
    );
  }

  String _totalLabel(List<BudgetCategory> items) {
    final int totalNgwee = items.fold(0, (sum, item) => sum + item.amountNgwee);
    return formatZmwFromNgwee(totalNgwee, withCode: false, showDecimals: false);
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          formatZmwFromNgwee(category.amountNgwee),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            '${category.percentage}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
