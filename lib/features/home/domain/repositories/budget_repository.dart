abstract class BudgetRepository {
  Map<String, int> getCategoryLimitsNgwee();

  void setCategoryLimitNgwee(String category, int limitNgwee);

  void removeCategoryLimit(String category);
}
