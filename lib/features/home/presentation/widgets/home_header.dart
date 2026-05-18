import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.monthlySpentNgwee,
    required this.monthlyBudgetNgwee,
    required this.onNotificationTap,
    required this.monthLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.hasAlerts = true,
  });

  final String userName;
  final int monthlySpentNgwee;
  final int monthlyBudgetNgwee;
  final VoidCallback onNotificationTap;
  final String monthLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool hasAlerts;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String initials = _initials(userName);
    final bool hasBudget = monthlyBudgetNgwee > 0;
    final int remainingNgwee = hasBudget
        ? (monthlyBudgetNgwee - monthlySpentNgwee).clamp(0, monthlyBudgetNgwee)
        : 0;
    final double usage = hasBudget
        ? (monthlySpentNgwee / monthlyBudgetNgwee).clamp(0.0, 1.0)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8BB4FF), Color(0xFFF8C14A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.accentOrange,
                    ),
                  ),
                  Text(userName, style: textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    monthLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onNotificationTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                    ),
                    if (hasAlerts)
                      Positioned(
                        top: 14,
                        right: 12,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFB3B3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0E7DB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'This month',
                  value: formatZmwFromNgwee(monthlySpentNgwee),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  label: hasBudget ? 'Left to spend' : 'Budget status',
                  value: hasBudget
                      ? formatZmwFromNgwee(remainingNgwee)
                      : 'Set your first budget',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: usage,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0EBE3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentOrange,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'S';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
