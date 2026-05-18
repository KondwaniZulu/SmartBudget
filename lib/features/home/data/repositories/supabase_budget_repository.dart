import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/features/home/domain/repositories/budget_repository.dart';

class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository._({
    required SupabaseClient client,
    required String userId,
    required Map<String, int> limitsNgwee,
  }) : _client = client,
       _userId = userId,
       _limitsNgwee = limitsNgwee;

  final SupabaseClient _client;
  final String _userId;
  final Map<String, int> _limitsNgwee;

  static Future<SupabaseBudgetRepository> create({
    required SupabaseClient client,
    required String userId,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month, 1);

    final List<dynamic> rows = await client
        .from('budget_limits')
        .select()
        .eq('user_id', userId)
        .eq('month_start', monthStart.toIso8601String().split('T').first);

    final Map<String, int> limitsNgwee = <String, int>{
      for (final row in rows)
        row['category'] as String: row['limit_ngwee'] as int,
    };

    return SupabaseBudgetRepository._(
      client: client,
      userId: userId,
      limitsNgwee: limitsNgwee,
    );
  }

  @override
  Map<String, int> getCategoryLimitsNgwee() {
    return Map<String, int>.unmodifiable(_limitsNgwee);
  }

  @override
  void setCategoryLimitNgwee(String category, int limitNgwee) {
    _limitsNgwee[category] = limitNgwee;
    unawaited(_persistLimit(category, limitNgwee));
  }

  @override
  void removeCategoryLimit(String category) {
    _limitsNgwee.remove(category);
    unawaited(_deleteLimit(category));
  }

  Future<void> _persistLimit(String category, int limitNgwee) async {
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month, 1);

    try {
      await _client.from('budget_limits').upsert({
        'user_id': _userId,
        'category': category,
        'month_start': monthStart.toIso8601String().split('T').first,
        'limit_ngwee': limitNgwee,
      }, onConflict: 'user_id,category,month_start');
    } catch (error, stackTrace) {
      debugPrint('Supabase upsert budget limit failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _deleteLimit(String category) async {
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month, 1);

    try {
      await _client
          .from('budget_limits')
          .delete()
          .eq('user_id', _userId)
          .eq('category', category)
          .eq('month_start', monthStart.toIso8601String().split('T').first);
    } catch (error, stackTrace) {
      debugPrint('Supabase delete budget limit failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
