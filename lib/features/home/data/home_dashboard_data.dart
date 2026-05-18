import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/features/home/domain/budget_category.dart';
import 'package:smartbudget_app/features/home/domain/quick_action.dart';
import 'package:smartbudget_app/features/home/domain/recent_activity.dart';

class HomeDashboardData {
  static const String userName = 'Kondwani';
  static const int totalBalanceNgwee = 1245030;
  static const int incomeNgwee = 420000;
  static const int outcomeNgwee = 215000;
  static const int monthlyBudgetNgwee = 400000;
  static const int monthlySpentNgwee = 287500;

  static const List<BudgetCategory> categories = [
    BudgetCategory(
      name: 'Food',
      amountNgwee: 120000,
      percentage: 35,
      color: AppColors.teal,
    ),
    BudgetCategory(
      name: 'Shopping',
      amountNgwee: 80000,
      percentage: 23,
      color: AppColors.amber,
    ),
    BudgetCategory(
      name: 'Transport',
      amountNgwee: 60000,
      percentage: 18,
      color: AppColors.gold,
    ),
    BudgetCategory(
      name: 'Health',
      amountNgwee: 45000,
      percentage: 13,
      color: AppColors.blue,
    ),
    BudgetCategory(
      name: 'Tax',
      amountNgwee: 35000,
      percentage: 11,
      color: AppColors.indigo,
    ),
  ];

  static const List<QuickAction> quickActions = [
    QuickAction(
      type: QuickActionType.addExpense,
      label: 'Add Expense',
      icon: Icons.add_card_rounded,
      color: AppColors.danger,
    ),
    QuickAction(
      type: QuickActionType.setBudget,
      label: 'Set Budget',
      icon: Icons.tune_rounded,
      color: AppColors.accentOrange,
    ),
    QuickAction(
      type: QuickActionType.addIncome,
      label: 'Transfer',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.blue,
    ),
  ];

  static const List<RecentActivity> recentActivities = [
    RecentActivity(
      title: 'Grocery Store',
      subtitle: 'Food • Today',
      amountNgwee: 8600,
      icon: Icons.shopping_bag_outlined,
      iconBackground: AppColors.teal,
    ),
    RecentActivity(
      title: 'Bus Top-Up',
      subtitle: 'Transport • Yesterday',
      amountNgwee: 2400,
      icon: Icons.directions_bus_outlined,
      iconBackground: AppColors.gold,
    ),
    RecentActivity(
      title: 'Freelance Payout',
      subtitle: 'Income • 2 days ago',
      amountNgwee: 48000,
      icon: Icons.wallet_outlined,
      iconBackground: AppColors.success,
      isExpense: false,
    ),
  ];
}
