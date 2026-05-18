import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/features/home/domain/repositories/transaction_repository.dart';
import 'package:smartbudget_app/features/home/domain/transaction_entry.dart';
import 'package:smartbudget_app/features/home/domain/transaction_type.dart';

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository._({
    required SupabaseClient client,
    required String userId,
    required List<TransactionEntry> items,
  }) : _client = client,
       _userId = userId,
       _items = items;

  final SupabaseClient _client;
  final String _userId;
  final List<TransactionEntry> _items;
  final Random _random = Random.secure();

  static Future<SupabaseTransactionRepository> create({
    required SupabaseClient client,
    required String userId,
  }) async {
    final List<dynamic> rows = await client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('transaction_date', ascending: false);

    final List<TransactionEntry> items = rows.map((row) {
      return TransactionEntry(
        id: row['id'].toString(),
        title: row['title'] as String,
        amountNgwee: row['amount_ngwee'] as int,
        category: row['category'] as String,
        date: DateTime.parse(row['transaction_date'] as String),
        type: (row['type'] as String) == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        note: row['note'] as String?,
      );
    }).toList();

    return SupabaseTransactionRepository._(
      client: client,
      userId: userId,
      items: items,
    );
  }

  @override
  List<TransactionEntry> getAll() {
    return List<TransactionEntry>.unmodifiable(_items);
  }

  @override
  String nextId() {
    return _generateUuidV4();
  }

  @override
  Future<void> upsert(TransactionEntry transaction) async {
    await _persistUpsert(transaction);
    final int index = _items.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      _items.add(transaction);
      return;
    }
    _items[index] = transaction;
  }

  @override
  Future<void> deleteById(String id) async {
    await _persistDelete(id);
    _items.removeWhere((item) => item.id == id);
  }

  Future<void> _persistUpsert(TransactionEntry item) async {
    try {
      await _client.from('transactions').upsert({
        'id': item.id,
        'user_id': _userId,
        'title': item.title,
        'amount_ngwee': item.amountNgwee,
        'type': item.type == TransactionType.income ? 'income' : 'expense',
        'category': item.category,
        'note': item.note,
        'transaction_date': item.date.toIso8601String().split('T').first,
      }, onConflict: 'id');
    } catch (error, stackTrace) {
      debugPrint('Supabase upsert transaction failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _persistDelete(String id) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (error, stackTrace) {
      debugPrint('Supabase delete transaction failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  String _generateUuidV4() {
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final String hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
