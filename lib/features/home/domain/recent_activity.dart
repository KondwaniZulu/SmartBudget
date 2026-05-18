import 'package:flutter/material.dart';

class RecentActivity {
  const RecentActivity({
    required this.title,
    required this.subtitle,
    required this.amountNgwee,
    required this.icon,
    required this.iconBackground,
    this.isExpense = true,
  });

  final String title;
  final String subtitle;
  final int amountNgwee;
  final IconData icon;
  final Color iconBackground;
  final bool isExpense;
}
