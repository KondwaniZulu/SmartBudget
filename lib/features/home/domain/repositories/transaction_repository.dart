import 'package:smartbudget_app/features/home/domain/transaction_entry.dart';

abstract class TransactionRepository {
  List<TransactionEntry> getAll();

  String nextId();

  Future<void> upsert(TransactionEntry transaction);

  Future<void> deleteById(String id);
}
