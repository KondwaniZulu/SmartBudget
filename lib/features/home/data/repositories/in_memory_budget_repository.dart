import 'package:smartbudget_app/features/home/domain/repositories/budget_repository.dart';

class InMemoryBudgetRepository implements BudgetRepository {
  InMemoryBudgetRepository({required Map<String, int> initialLimitsNgwee})
    : _limitsNgwee = <String, int>{...initialLimitsNgwee};

  final Map<String, int> _limitsNgwee;

  @override
  Map<String, int> getCategoryLimitsNgwee() {
    return Map<String, int>.unmodifiable(_limitsNgwee);
  }

  @override
  void setCategoryLimitNgwee(String category, int limitNgwee) {
    _limitsNgwee[category] = limitNgwee;
  }

  @override
  void removeCategoryLimit(String category) {
    _limitsNgwee.remove(category);
  }
}
