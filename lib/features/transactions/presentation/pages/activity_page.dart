import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/data/student_budget_store.dart';
import 'package:smartbudget_app/features/home/domain/transaction_entry.dart';
import 'package:smartbudget_app/features/home/domain/transaction_type.dart';
import 'package:smartbudget_app/features/transactions/presentation/pages/add_transaction_page.dart';

enum ActivityFilter { all, income, expense }

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key, required this.store});

  final StudentBudgetStore store;

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontalPadding = width >= 520 ? 28 : 20;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final List<TransactionEntry> sorted = [...widget.store.transactions]
              ..retainWhere(
                (entry) =>
                    entry.date.year == widget.store.selectedMonth.year &&
                    entry.date.month == widget.store.selectedMonth.month,
              )
              ..sort((a, b) => b.date.compareTo(a.date));
            final List<TransactionEntry> filtered = sorted.where((entry) {
              if (_filter == ActivityFilter.income) {
                return entry.type == TransactionType.income;
              }
              if (_filter == ActivityFilter.expense) {
                return entry.type == TransactionType.expense;
              }
              return true;
            }).toList();

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                24,
              ),
              children: [
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Track every transaction and edit mistakes quickly.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                _MonthSwitcher(
                  label: widget.store.selectedMonthLabel,
                  onPrevious: widget.store.goToPreviousMonth,
                  onNext: widget.store.goToNextMonth,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == ActivityFilter.all,
                      onTap: () => setState(() => _filter = ActivityFilter.all),
                    ),
                    _FilterChip(
                      label: 'Income',
                      selected: _filter == ActivityFilter.income,
                      onTap: () =>
                          setState(() => _filter = ActivityFilter.income),
                    ),
                    _FilterChip(
                      label: 'Expense',
                      selected: _filter == ActivityFilter.expense,
                      onTap: () =>
                          setState(() => _filter = ActivityFilter.expense),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  _EmptyState(onAdd: _openQuickAddChooser)
                else
                  ...filtered.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionTile(
                        entry: entry,
                        onEdit: () => _editTransaction(entry),
                        onDelete: () => _confirmDelete(entry),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickAddChooser,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    );
  }

  Future<void> _openQuickAddChooser() async {
    final TransactionType? type = await showModalBottomSheet<TransactionType>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.trending_down_rounded),
                title: const Text('Add Expense'),
                onTap: () => Navigator.of(context).pop(TransactionType.expense),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up_rounded),
                title: const Text('Add Income'),
                onTap: () => Navigator.of(context).pop(TransactionType.income),
              ),
            ],
          ),
        );
      },
    );

    if (type == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddTransactionPage(
          initialType: type,
          newIdFactory: widget.store.nextTransactionId,
          extraExpenseCategories:
              widget.store.expenseCategoriesFromTransactions,
          extraIncomeCategories: widget.store.incomeCategoriesFromTransactions,
          onSubmit: widget.store.upsertTransaction,
        ),
      ),
    );
  }

  Future<void> _editTransaction(TransactionEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddTransactionPage(
          initialType: entry.type,
          initialTransaction: entry,
          extraExpenseCategories:
              widget.store.expenseCategoriesFromTransactions,
          extraIncomeCategories: widget.store.incomeCategoriesFromTransactions,
          onSubmit: widget.store.upsertTransaction,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(TransactionEntry entry) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text('Delete "${entry.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await widget.store.deleteTransaction(entry.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $error')),
      );
    }
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color accent = entry.isExpense ? AppColors.danger : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              entry.isExpense
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.category} • ${_formatDate(entry.date)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.isExpense
                ? '-${formatZmwFromNgwee(entry.amountNgwee)}'
                : '+${formatZmwFromNgwee(entry.amountNgwee)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: accent),
          ),
          PopupMenuButton<_TileAction>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == _TileAction.edit) {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<_TileAction>(
                value: _TileAction.edit,
                child: Text('Edit'),
              ),
              PopupMenuItem<_TileAction>(
                value: _TileAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Start by adding your first expense or income.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE8E1D8)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

enum _TileAction { edit, delete }
