import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/domain/transaction_entry.dart';
import 'package:smartbudget_app/features/home/domain/transaction_type.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    required this.initialType,
    this.initialTransaction,
    this.newIdFactory,
    this.onSubmit,
    this.extraExpenseCategories = const <String>[],
    this.extraIncomeCategories = const <String>[],
  });

  final TransactionType initialType;
  final TransactionEntry? initialTransaction;
  final String Function()? newIdFactory;
  final Future<void> Function(TransactionEntry entry)? onSubmit;
  final List<String> extraExpenseCategories;
  final List<String> extraIncomeCategories;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  static const String _customCategoryOption = '__custom__';
  static const List<String> _expenseCategories = <String>[
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Tax',
    'School',
    'Other',
  ];

  static const List<String> _incomeCategories = <String>[
    'Allowance',
    'Scholarship',
    'Freelance',
    'Salary',
    'Gift',
    'Other',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();

  late TransactionType _selectedType;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final TransactionEntry? initial = widget.initialTransaction;
    _selectedType = initial?.type ?? widget.initialType;
    _selectedDate = initial?.date ?? DateTime.now();
    final List<String> categoryOptions = _categoryOptionsForType(_selectedType);
    if (initial != null && !categoryOptions.contains(initial.category)) {
      _selectedCategory = _customCategoryOption;
      _customCategoryController.text = initial.category;
    } else {
      _selectedCategory = initial?.category ?? categoryOptions.first;
    }
    _titleController.text = initial?.title ?? '';
    _amountController.text = initial == null
        ? ''
        : formatNgweeForInput(initial.amountNgwee);
    _notesController.text = initial?.note ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTransaction == null
              ? 'Add Transaction'
              : 'Edit Transaction',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.trending_down_rounded),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.trending_up_rounded),
                    ),
                  ],
                  selected: <TransactionType>{_selectedType},
                  onSelectionChanged: _submitting
                      ? null
                      : (Set<TransactionType> selection) {
                          setState(() {
                            _selectedType = selection.first;
                            final List<String> categories =
                                _categoryOptionsForType(_selectedType);
                            if (!categories.contains(_selectedCategory)) {
                              _selectedCategory = categories.first;
                              _customCategoryController.clear();
                            }
                          });
                        },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Library Printing',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  enabled: !_submitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'ZMW ',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter amount';
                    }
                    final int? amountNgwee = parseZmwInputToNgwee(value);
                    if (amountNgwee == null || amountNgwee <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey<TransactionType>(_selectedType),
                  initialValue: _selectedCategory,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryOptionsForType(_selectedType)
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category == _customCategoryOption
                                ? 'Custom category'
                                : category,
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select a category';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_submitting || value == null) {
                      return;
                    }
                    if (value == _customCategoryOption &&
                        _customCategoryController.text.trim().isEmpty) {
                      _customCategoryController.clear();
                    }
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                if (_selectedCategory == _customCategoryOption) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _customCategoryController,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Custom category',
                      hintText: 'e.g. Airtime',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedCategory != _customCategoryOption) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a custom category';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                InkWell(
                  onTap: _submitting ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(_selectedDate)),
                        const Icon(Icons.calendar_today_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  enabled: !_submitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedType == TransactionType.expense
                          ? AppColors.danger
                          : AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(
                      _submitting
                          ? Icons.hourglass_top_rounded
                          : _selectedType == TransactionType.expense
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                    ),
                    label: Text(
                      _submitting
                          ? 'Saving...'
                          : widget.initialTransaction == null
                          ? _selectedType == TransactionType.expense
                                ? 'Save Expense'
                                : 'Save Income'
                          : 'Save Changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _categoryOptionsForType(TransactionType type) {
    final List<String> base = type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;
    final List<String> extras = type == TransactionType.expense
        ? widget.extraExpenseCategories
        : widget.extraIncomeCategories;
    final Set<String> merged = <String>{...base, ...extras};
    final List<String> sorted = merged.toList()..sort();
    return <String>[...sorted, _customCategoryOption];
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? amountNgwee = parseZmwInputToNgwee(_amountController.text);
    if (amountNgwee == null || amountNgwee <= 0) {
      return;
    }
    final String resolvedCategory = _normalizeCategoryLabel(
      _selectedCategory == _customCategoryOption
          ? _customCategoryController.text
          : _selectedCategory,
    );
    if (resolvedCategory.isEmpty) {
      return;
    }
    final String id =
        widget.initialTransaction?.id ??
        widget.newIdFactory?.call() ??
        'txn_${DateTime.now().microsecondsSinceEpoch}';
    final TransactionEntry entry = TransactionEntry(
      id: id,
      title: _titleController.text.trim(),
      amountNgwee: amountNgwee,
      category: resolvedCategory,
      date: _selectedDate,
      type: _selectedType,
      note: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (widget.onSubmit == null) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(entry);
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.onSubmit!.call(entry);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(entry);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _normalizeCategoryLabel(String input) {
    final String trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed
        .split(' ')
        .map((word) {
          final String lower = word.toLowerCase();
          return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
