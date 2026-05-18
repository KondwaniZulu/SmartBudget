import 'package:smartbudget_app/features/home/domain/repositories/transaction_repository.dart';
import 'package:smartbudget_app/features/home/domain/transaction_entry.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({required List<TransactionEntry> seed})
    : _items = [...seed];

  final List<TransactionEntry> _items;
  int _nextId = 1;

  @override
  List<TransactionEntry> getAll() {
    int maxSeen = 0;
    for (final TransactionEntry item in _items) {
      final int? parsed = _parseId(item.id);
      if (parsed != null && parsed > maxSeen) {
        maxSeen = parsed;
      }
    }
    if (maxSeen >= _nextId) {
      _nextId = maxSeen + 1;
    }
    return List<TransactionEntry>.unmodifiable(_items);
  }

  @override
  String nextId() {
    final String id = 'txn_$_nextId';
    _nextId += 1;
    return id;
  }

  @override
  Future<void> upsert(TransactionEntry transaction) async {
    final int index = _items.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      _items.add(transaction);
      return;
    }
    _items[index] = transaction;
  }

  @override
  Future<void> deleteById(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  int? _parseId(String id) {
    if (!id.startsWith('txn_')) {
      return null;
    }
    return int.tryParse(id.substring(4));
  }
}
