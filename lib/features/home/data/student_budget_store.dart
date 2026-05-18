import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/features/home/data/repositories/in_memory_budget_repository.dart';
import 'package:smartbudget_app/features/home/data/repositories/in_memory_transaction_repository.dart';
import 'package:smartbudget_app/features/home/domain/budget_category.dart';
import 'package:smartbudget_app/features/home/domain/quick_action.dart';
import 'package:smartbudget_app/features/home/domain/recent_activity.dart';
import 'package:smartbudget_app/features/home/domain/repositories/budget_repository.dart';
import 'package:smartbudget_app/features/home/domain/repositories/transaction_repository.dart';
import 'package:smartbudget_app/features/home/domain/transaction_entry.dart';
import 'package:smartbudget_app/features/home/domain/transaction_type.dart';

class StudentBudgetStore extends ChangeNotifier {
  static const String _defaultUserName = 'Kondwani';
  static const int _defaultOpeningBalanceNgwee = 1040030;

  StudentBudgetStore({
    TransactionRepository? transactionRepository,
    BudgetRepository? budgetRepository,
    String? initialUserName,
    int? initialOpeningBalanceNgwee,
  }) : _transactionRepository =
           transactionRepository ??
           InMemoryTransactionRepository(seed: _seedTransactions()),
       _budgetRepository =
           budgetRepository ??
           InMemoryBudgetRepository(
             initialLimitsNgwee: _seedBudgetLimitsNgwee(),
           ),
       quickActions = const [
         QuickAction(
           type: QuickActionType.addExpense,
           label: 'Add Expense',
           icon: Icons.add_card_rounded,
           color: AppColors.danger,
         ),
         QuickAction(
           type: QuickActionType.addIncome,
           label: 'Add Income',
           icon: Icons.payments_rounded,
           color: AppColors.success,
         ),
         QuickAction(
           type: QuickActionType.setBudget,
           label: 'Set Budget',
           icon: Icons.tune_rounded,
           color: AppColors.accentOrange,
         ),
       ],
       _userName = initialUserName ?? _defaultUserName,
       _openingBalanceNgwee =
           initialOpeningBalanceNgwee ?? _defaultOpeningBalanceNgwee;

  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final List<QuickAction> quickActions;
  String _userName;
  int _openingBalanceNgwee;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  String get userName => _userName;

  int get openingBalanceNgwee => _openingBalanceNgwee;

  DateTime get selectedMonth => _selectedMonth;

  String get selectedMonthLabel {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  List<TransactionEntry> get transactions => _transactionRepository.getAll();

  List<TransactionEntry> get recentTransactions {
    final List<TransactionEntry> sorted = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(6).toList();
  }

  int get totalIncomeNgwee => transactions
      .where((item) => item.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amountNgwee);

  int get totalExpenseNgwee => transactions
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amountNgwee);

  int get totalBalanceNgwee =>
      _openingBalanceNgwee + totalIncomeNgwee - totalExpenseNgwee;

  int get monthlySpentNgwee {
    return transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.date.year == _selectedMonth.year &&
              item.date.month == _selectedMonth.month,
        )
        .fold(0, (sum, item) => sum + item.amountNgwee);
  }

  List<BudgetCategory> get budgetCategories {
    final Map<String, int> grouped = <String, int>{};

    for (final TransactionEntry item in transactions) {
      if (item.type != TransactionType.expense) {
        continue;
      }
      if (item.date.year != _selectedMonth.year ||
          item.date.month != _selectedMonth.month) {
        continue;
      }
      grouped.update(
        item.category,
        (value) => value + item.amountNgwee,
        ifAbsent: () => item.amountNgwee,
      );
    }

    final int total = grouped.values.fold(0, (sum, value) => sum + value);
    if (total == 0) {
      return const <BudgetCategory>[];
    }

    final List<MapEntry<String, int>> sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) {
      final int percentage = ((entry.value / total) * 100).round().clamp(
        1,
        100,
      );
      return BudgetCategory(
        name: entry.key,
        amountNgwee: entry.value,
        percentage: percentage,
        color: _colorForCategory(entry.key),
      );
    }).toList();
  }

  List<RecentActivity> get recentActivities {
    return recentTransactions.map((entry) {
      return RecentActivity(
        title: entry.title,
        subtitle: '${entry.category} • ${_dayLabel(entry.date)}',
        amountNgwee: entry.amountNgwee,
        icon: _iconForCategory(entry.category),
        iconBackground: _colorForCategory(entry.category),
        isExpense: entry.isExpense,
      );
    }).toList();
  }

  List<String> get trackedBudgetCategories {
    final Set<String> categories = <String>{
      ..._budgetRepository.getCategoryLimitsNgwee().keys,
    };
    for (final TransactionEntry item in transactions) {
      if (item.type == TransactionType.expense) {
        categories.add(item.category);
      }
    }
    final List<String> sorted = categories.toList()..sort();
    return sorted;
  }

  List<String> get expenseCategoriesFromTransactions {
    final Set<String> categories = transactions
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.category)
        .toSet();
    final List<String> sorted = categories.toList()..sort();
    return sorted;
  }

  List<String> get incomeCategoriesFromTransactions {
    final Set<String> categories = transactions
        .where((item) => item.type == TransactionType.income)
        .map((item) => item.category)
        .toSet();
    final List<String> sorted = categories.toList()..sort();
    return sorted;
  }

  int budgetLimitForCategoryNgwee(String category) {
    return _budgetRepository.getCategoryLimitsNgwee()[category] ?? 0;
  }

  bool hasBudgetLimitForCategory(String category) {
    return _budgetRepository.getCategoryLimitsNgwee().containsKey(category);
  }

  int spentForCategoryThisMonthNgwee(String category) {
    return transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.category == category &&
              item.date.year == _selectedMonth.year &&
              item.date.month == _selectedMonth.month,
        )
        .fold(0, (sum, item) => sum + item.amountNgwee);
  }

  int get totalBudgetLimitNgwee => _budgetRepository
      .getCategoryLimitsNgwee()
      .values
      .fold(0, (sum, item) => sum + item);

  int get totalBudgetRemainingNgwee =>
      totalBudgetLimitNgwee - monthlySpentNgwee;

  Future<void> addTransaction(TransactionEntry entry) async {
    await _transactionRepository.upsert(entry);
    notifyListeners();
  }

  Future<void> upsertTransaction(TransactionEntry entry) async {
    await _transactionRepository.upsert(entry);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionRepository.deleteById(id);
    notifyListeners();
  }

  String nextTransactionId() {
    return _transactionRepository.nextId();
  }

  TransactionEntry createTransaction({
    required String title,
    required int amountNgwee,
    required String category,
    required DateTime date,
    required TransactionType type,
    String? note,
  }) {
    return TransactionEntry(
      id: _transactionRepository.nextId(),
      title: title,
      amountNgwee: amountNgwee,
      category: category,
      date: date,
      type: type,
      note: note,
    );
  }

  void setBudgetLimitNgwee(String category, int limitNgwee) {
    _budgetRepository.setCategoryLimitNgwee(category, limitNgwee);
    notifyListeners();
  }

  void removeBudgetCategory(String category) {
    _budgetRepository.removeCategoryLimit(category);
    notifyListeners();
  }

  void updateUserContext({String? userName, int? openingBalanceNgwee}) {
    final String? trimmedName = userName?.trim();
    final String nextName = (trimmedName == null || trimmedName.isEmpty)
        ? _userName
        : trimmedName;
    final int nextOpening =
        openingBalanceNgwee == null || openingBalanceNgwee < 0
        ? _openingBalanceNgwee
        : openingBalanceNgwee;

    if (nextName == _userName && nextOpening == _openingBalanceNgwee) {
      return;
    }

    _userName = nextName;
    _openingBalanceNgwee = nextOpening;
    notifyListeners();
  }

  void goToPreviousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void goToNextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    notifyListeners();
  }

  List<TransactionEntry> transactionsForMonth(DateTime month) {
    return transactions
        .where(
          (item) =>
              item.date.year == month.year && item.date.month == month.month,
        )
        .toList();
  }

  int incomeForMonthNgwee(DateTime month) {
    return transactionsForMonth(month)
        .where((item) => item.type == TransactionType.income)
        .fold(0, (sum, item) => sum + item.amountNgwee);
  }

  int expenseForMonthNgwee(DateTime month) {
    return transactionsForMonth(month)
        .where((item) => item.type == TransactionType.expense)
        .fold(0, (sum, item) => sum + item.amountNgwee);
  }

  static Map<String, int> _seedBudgetLimitsNgwee() {
    return <String, int>{
      'Food': 130000,
      'Shopping': 85000,
      'Transport': 65000,
      'Health': 50000,
      'Tax': 40000,
    };
  }

  static List<TransactionEntry> _seedTransactions() {
    final DateTime now = DateTime.now();

    return <TransactionEntry>[
      TransactionEntry(
        id: 'txn_1',
        title: 'Student Allowance',
        amountNgwee: 320000,
        category: 'Allowance',
        date: DateTime(now.year, now.month, 2),
        type: TransactionType.income,
      ),
      TransactionEntry(
        id: 'txn_2',
        title: 'Freelance Payout',
        amountNgwee: 100000,
        category: 'Freelance',
        date: now.subtract(const Duration(days: 2)),
        type: TransactionType.income,
      ),
      TransactionEntry(
        id: 'txn_3',
        title: 'Grocery Store',
        amountNgwee: 120000,
        category: 'Food',
        date: now.subtract(const Duration(days: 1)),
        type: TransactionType.expense,
      ),
      TransactionEntry(
        id: 'txn_4',
        title: 'Campus Shop',
        amountNgwee: 80000,
        category: 'Shopping',
        date: now.subtract(const Duration(days: 4)),
        type: TransactionType.expense,
      ),
      TransactionEntry(
        id: 'txn_5',
        title: 'Bus Top-Up',
        amountNgwee: 60000,
        category: 'Transport',
        date: now.subtract(const Duration(days: 1)),
        type: TransactionType.expense,
      ),
      TransactionEntry(
        id: 'txn_6',
        title: 'Pharmacy',
        amountNgwee: 45000,
        category: 'Health',
        date: now.subtract(const Duration(days: 5)),
        type: TransactionType.expense,
      ),
      TransactionEntry(
        id: 'txn_7',
        title: 'Tax',
        amountNgwee: 35000,
        category: 'Tax',
        date: now.subtract(const Duration(days: 6)),
        type: TransactionType.expense,
      ),
    ];
  }

  static String _dayLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);
    final int diff = today.difference(target).inDays;

    if (diff == 0) {
      return 'Today';
    }
    if (diff == 1) {
      return 'Yesterday';
    }
    if (diff > 1) {
      return '$diff days ago';
    }

    return 'Upcoming';
  }

  static Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.teal;
      case 'shopping':
        return AppColors.amber;
      case 'transport':
        return AppColors.gold;
      case 'health':
        return AppColors.blue;
      case 'tax':
        return AppColors.indigo;
      case 'allowance':
      case 'salary':
      case 'scholarship':
      case 'freelance':
        return AppColors.success;
      default:
        return AppColors.accentOrange;
    }
  }

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'transport':
        return Icons.directions_bus_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'tax':
        return Icons.account_balance_outlined;
      case 'allowance':
      case 'salary':
      case 'scholarship':
      case 'freelance':
        return Icons.payments_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
