import 'package:flutter/material.dart';

class BudgetCategory {
  const BudgetCategory({
    required this.name,
    required this.amountNgwee,
    required this.percentage,
    required this.color,
  });

  final String name;
  final int amountNgwee;
  final int percentage;
  final Color color;
}
