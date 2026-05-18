import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/data/student_budget_store.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, required this.store});

  final StudentBudgetStore store;

  @override
  State<BudgetPage> createState() => BudgetPageState();
}

class BudgetPageState extends State<BudgetPage> {
  bool _editorOpen = false;

  Future<void> openBudgetEditor({String? category}) async {
    if (_editorOpen || !mounted) {
      return;
    }

    final List<String> categories = widget.store.trackedBudgetCategories;
    final String? selectedCategory =
        category ?? (categories.isEmpty ? null : categories.first);

    _editorOpen = true;
    try {
      final _BudgetEditorResult? result = await _showBudgetSheet(
        initialCategory: selectedCategory,
      );
      if (!mounted || result == null) {
        return;
      }

      if (result.deleteCategory) {
        widget.store.removeBudgetCategory(result.category);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${result.category} removed.')));
        return;
      }

      widget.store.setBudgetLimitNgwee(result.category, result.limitNgwee);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.category} budget saved.')),
      );
    } finally {
      _editorOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontalPadding = width >= 520 ? 28 : 20;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                24,
              ),
              children: [
                Text(
                  'Budget Plan',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Set monthly limits per category and track overspending.',
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
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => openBudgetEditor(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Category Budget'),
                  ),
                ),
                const SizedBox(height: 18),
                _BudgetSummaryCard(store: widget.store),
                const SizedBox(height: 16),
                if (widget.store.trackedBudgetCategories.isEmpty)
                  _EmptyBudgetState(onAddPressed: () => openBudgetEditor())
                else
                  ...widget.store.trackedBudgetCategories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BudgetCategoryTile(
                        category: category,
                        spentNgwee: widget.store.spentForCategoryThisMonthNgwee(
                          category,
                        ),
                        limitNgwee: widget.store.budgetLimitForCategoryNgwee(
                          category,
                        ),
                        hasBudgetLimit: widget.store.hasBudgetLimitForCategory(
                          category,
                        ),
                        onEdit: () => openBudgetEditor(category: category),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<_BudgetEditorResult?> _showBudgetSheet({String? initialCategory}) {
    String categoryInput = initialCategory ?? '';
    String limitInput = initialCategory == null
        ? ''
        : formatNgweeForInput(
            widget.store.budgetLimitForCategoryNgwee(initialCategory),
          );
    String? categoryError;
    String? limitError;
    final bool canDelete =
        initialCategory != null &&
        widget.store.hasBudgetLimitForCategory(initialCategory);

    return showModalBottomSheet<_BudgetEditorResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initialCategory == null
                        ? 'Add Budget Category'
                        : 'Set $initialCategory Budget',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: categoryInput,
                    enabled: initialCategory == null,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      hintText: 'Food, Transport, Airtime',
                      border: const OutlineInputBorder(),
                      errorText: categoryError,
                    ),
                    onChanged: (value) {
                      categoryInput = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: limitInput,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monthly limit',
                      prefixText: 'ZMW ',
                      border: const OutlineInputBorder(),
                      errorText: limitError,
                    ),
                    onChanged: (value) {
                      limitInput = value;
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final String category = _normalizeCategoryLabel(
                          categoryInput,
                        );
                        final int? valueNgwee = parseZmwInputToNgwee(
                          limitInput,
                        );

                        setModalState(() {
                          categoryError = category.isEmpty
                              ? 'Category is required.'
                              : null;
                          if (valueNgwee == null) {
                            limitError = 'Enter a valid amount.';
                          } else if (valueNgwee < 0) {
                            limitError = 'Limit cannot be negative.';
                          } else {
                            limitError = null;
                          }
                        });

                        if (category.isEmpty ||
                            valueNgwee == null ||
                            valueNgwee < 0) {
                          return;
                        }

                        Navigator.of(context).pop(
                          _BudgetEditorResult.save(
                            category: category,
                            limitNgwee: valueNgwee,
                          ),
                        );
                      },
                      child: const Text('Save Budget'),
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            _BudgetEditorResult.delete(
                              category: initialCategory,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove This Budget'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _normalizeCategoryLabel(String input) {
    final String trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          final String lower = word.toLowerCase();
          return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
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

class _BudgetEditorResult {
  const _BudgetEditorResult._({
    required this.category,
    required this.limitNgwee,
    required this.deleteCategory,
  });

  final String category;
  final int limitNgwee;
  final bool deleteCategory;

  factory _BudgetEditorResult.save({
    required String category,
    required int limitNgwee,
  }) {
    return _BudgetEditorResult._(
      category: category,
      limitNgwee: limitNgwee,
      deleteCategory: false,
    );
  }

  factory _BudgetEditorResult.delete({required String category}) {
    return _BudgetEditorResult._(
      category: category,
      limitNgwee: 0,
      deleteCategory: true,
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No budget categories yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first monthly budget category to start tracking limits.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add category budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({required this.store});

  final StudentBudgetStore store;

  @override
  Widget build(BuildContext context) {
    final double usedRatio = store.totalBudgetLimitNgwee <= 0
        ? 0
        : (store.monthlySpentNgwee / store.totalBudgetLimitNgwee).clamp(
            0.0,
            1.0,
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Budget Usage',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatZmwFromNgwee(store.monthlySpentNgwee)} of ${formatZmwFromNgwee(store.totalBudgetLimitNgwee)}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usedRatio,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentYellow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            store.totalBudgetRemainingNgwee >= 0
                ? '${formatZmwFromNgwee(store.totalBudgetRemainingNgwee)} left this month'
                : '${formatZmwFromNgwee(store.totalBudgetRemainingNgwee.abs())} over budget',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: store.totalBudgetRemainingNgwee >= 0
                  ? Colors.white70
                  : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  const _BudgetCategoryTile({
    required this.category,
    required this.spentNgwee,
    required this.limitNgwee,
    required this.hasBudgetLimit,
    required this.onEdit,
  });

  final String category;
  final int spentNgwee;
  final int limitNgwee;
  final bool hasBudgetLimit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final double ratio = !hasBudgetLimit || limitNgwee <= 0
        ? 0
        : (spentNgwee / limitNgwee).clamp(0.0, 1.0);
    final bool over =
        hasBudgetLimit && limitNgwee > 0 && spentNgwee > limitNgwee;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(hasBudgetLimit ? 'Edit' : 'Set'),
              ),
            ],
          ),
          Text(
            hasBudgetLimit
                ? '${formatZmwFromNgwee(spentNgwee)} spent • ${formatZmwFromNgwee(limitNgwee)} limit'
                : '${formatZmwFromNgwee(spentNgwee)} spent • No limit set',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0EBE3),
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? AppColors.danger : AppColors.accentOrange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !hasBudgetLimit
                ? 'Set a limit to track this category'
                : over
                ? 'Over budget'
                : '${(ratio * 100).toStringAsFixed(0)}% used',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: !hasBudgetLimit
                  ? AppColors.textMuted
                  : over
                  ? AppColors.danger
                  : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
