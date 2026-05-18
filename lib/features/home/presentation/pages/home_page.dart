import 'package:flutter/material.dart';
import 'package:smartbudget_app/features/home/data/student_budget_store.dart';
import 'package:smartbudget_app/features/home/domain/quick_action.dart';
import 'package:smartbudget_app/features/home/domain/transaction_type.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/balance_card.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/budget_overview_card.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/home_header.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/income_outcome_card.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/monthly_goal_card.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/quick_actions_card.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/recent_activity_card.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/spending_trend_card.dart';
import 'package:smartbudget_app/features/transactions/presentation/pages/add_transaction_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, this.onSetBudgetRequested});

  final StudentBudgetStore store;
  final Future<void> Function()? onSetBudgetRequested;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontalPadding = width >= 520 ? 28 : 20;

    return Scaffold(
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Stack(
            children: [
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFE8D8), Color(0xFFF7F5F2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    28,
                  ),
                  children: [
                    HomeHeader(
                      userName: store.userName,
                      monthlySpentNgwee: store.monthlySpentNgwee,
                      monthlyBudgetNgwee: store.totalBudgetLimitNgwee,
                      monthLabel: store.selectedMonthLabel,
                      onPreviousMonth: store.goToPreviousMonth,
                      onNextMonth: store.goToNextMonth,
                      hasAlerts: _buildAlerts().isNotEmpty,
                      onNotificationTap: () => _openNotificationsPanel(context),
                    ),
                    const SizedBox(height: 22),
                    BalanceCard(balanceNgwee: store.totalBalanceNgwee),
                    const SizedBox(height: 18),
                    IncomeOutcomeCard(
                      incomeNgwee: store.totalIncomeNgwee,
                      outcomeNgwee: store.totalExpenseNgwee,
                    ),
                    const SizedBox(height: 20),
                    MonthlyGoalCard(
                      monthlyBudgetNgwee: store.totalBudgetLimitNgwee,
                      spentAmountNgwee: store.monthlySpentNgwee,
                    ),
                    const SizedBox(height: 20),
                    QuickActionsCard(
                      actions: store.quickActions,
                      onActionTap: (action) =>
                          _handleQuickAction(context, action),
                    ),
                    const SizedBox(height: 20),
                    BudgetOverviewCard(categories: store.budgetCategories),
                    const SizedBox(height: 20),
                    SpendingTrendCard(
                      series: _trendSeries(),
                      currentIncomeNgwee: store.incomeForMonthNgwee(
                        store.selectedMonth,
                      ),
                      currentExpenseNgwee: store.expenseForMonthNgwee(
                        store.selectedMonth,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RecentActivityCard(items: store.recentActivities),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleQuickAction(
    BuildContext context,
    QuickAction action,
  ) async {
    switch (action.type) {
      case QuickActionType.addExpense:
        await _openAddTransaction(context, TransactionType.expense);
        return;
      case QuickActionType.addIncome:
        await _openAddTransaction(context, TransactionType.income);
        return;
      case QuickActionType.setBudget:
        await onSetBudgetRequested?.call();
        return;
    }
  }

  Future<void> _openAddTransaction(
    BuildContext context,
    TransactionType initialType,
  ) async {
    final NavigatorState navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AddTransactionPage(
          initialType: initialType,
          newIdFactory: store.nextTransactionId,
          extraExpenseCategories: store.expenseCategoriesFromTransactions,
          extraIncomeCategories: store.incomeCategoriesFromTransactions,
          onSubmit: (entry) async {
            await store.addTransaction(entry);
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  entry.type == TransactionType.expense
                      ? 'Expense added'
                      : 'Income added',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<_HomeAlert> _buildAlerts() {
    final List<_HomeAlert> alerts = <_HomeAlert>[];

    if (store.transactions.isEmpty) {
      alerts.add(
        const _HomeAlert(
          title: 'No transactions yet',
          message: 'Add your first income or expense to start tracking.',
          icon: Icons.receipt_long_outlined,
          action: _HomeAlertAction.addTransaction,
        ),
      );
    }

    if (store.totalBudgetLimitNgwee <= 0) {
      alerts.add(
        const _HomeAlert(
          title: 'No monthly budget set',
          message:
              'Create a budget limit so your dashboard can track progress.',
          icon: Icons.pie_chart_outline_rounded,
          action: _HomeAlertAction.setBudget,
        ),
      );
    }

    if (store.totalBudgetRemainingNgwee < 0) {
      alerts.add(
        _HomeAlert(
          title: 'You are over budget',
          message:
              'Overspent by ${(-store.totalBudgetRemainingNgwee / 100).toStringAsFixed(2)} ZMW this month.',
          icon: Icons.warning_amber_rounded,
          action: _HomeAlertAction.none,
        ),
      );
    }

    for (final String category in store.trackedBudgetCategories) {
      if (!store.hasBudgetLimitForCategory(category)) {
        continue;
      }
      final int limit = store.budgetLimitForCategoryNgwee(category);
      if (limit <= 0) {
        continue;
      }
      final int spent = store.spentForCategoryThisMonthNgwee(category);
      if (spent <= limit) {
        continue;
      }
      alerts.add(
        _HomeAlert(
          title: '$category is over budget',
          message:
              '${(spent / 100).toStringAsFixed(2)} ZMW spent vs ${(limit / 100).toStringAsFixed(2)} ZMW limit.',
          icon: Icons.trending_down_rounded,
          action: _HomeAlertAction.setBudget,
        ),
      );
    }

    return alerts.take(5).toList();
  }

  Future<void> _openNotificationsPanel(BuildContext context) async {
    final BuildContext parentContext = context;
    final List<_HomeAlert> alerts = _buildAlerts();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders & Alerts',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                if (alerts.isEmpty)
                  Text(
                    'No alerts right now. Keep up the good tracking.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                else
                  ...alerts.map(
                    (alert) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(alert.icon),
                      title: Text(alert.title),
                      subtitle: Text(alert.message),
                      trailing: alert.action == _HomeAlertAction.none
                          ? null
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: alert.action == _HomeAlertAction.none
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              if (alert.action == _HomeAlertAction.setBudget) {
                                await onSetBudgetRequested?.call();
                                return;
                              }
                              await _openAddTransaction(
                                parentContext,
                                TransactionType.expense,
                              );
                            },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MonthlyPoint> _trendSeries() {
    final DateTime selected = store.selectedMonth;
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return List<MonthlyPoint>.generate(4, (index) {
      final DateTime month = DateTime(
        selected.year,
        selected.month - (3 - index),
        1,
      );
      return MonthlyPoint(
        label: months[month.month - 1],
        expenseNgwee: store.expenseForMonthNgwee(month),
      );
    });
  }
}

enum _HomeAlertAction { none, setBudget, addTransaction }

class _HomeAlert {
  const _HomeAlert({
    required this.title,
    required this.message,
    required this.icon,
    required this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final _HomeAlertAction action;
}
