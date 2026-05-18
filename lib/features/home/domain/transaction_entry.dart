import 'package:smartbudget_app/features/home/domain/transaction_type.dart';

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.title,
    required this.amountNgwee,
    required this.category,
    required this.date,
    required this.type,
    this.note,
  });

  final String id;
  final String title;
  final int amountNgwee;
  final String category;
  final DateTime date;
  final TransactionType type;
  final String? note;

  bool get isExpense => type == TransactionType.expense;

  TransactionEntry copyWith({
    String? id,
    String? title,
    int? amountNgwee,
    String? category,
    DateTime? date,
    TransactionType? type,
    String? note,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amountNgwee: amountNgwee ?? this.amountNgwee,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
