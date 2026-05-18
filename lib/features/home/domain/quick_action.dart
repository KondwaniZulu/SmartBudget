import 'package:flutter/material.dart';

enum QuickActionType { addExpense, addIncome, setBudget }

class QuickAction {
  const QuickAction({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });

  final QuickActionType type;
  final String label;
  final IconData icon;
  final Color color;
}
