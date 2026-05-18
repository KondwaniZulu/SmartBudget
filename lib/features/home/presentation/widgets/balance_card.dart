import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.balanceNgwee});

  final int balanceNgwee;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SectionCard(
      backgroundColor: AppColors.cardDark,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 360;
          final double balanceFontSize = compact ? 36 : 44;

          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatZmwFromNgwee(balanceNgwee),
                        style: textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: balanceFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
