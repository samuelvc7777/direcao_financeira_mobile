import 'package:flutter/material.dart';

class HomeExpenseChartItem {
  const HomeExpenseChartItem({
    required this.categoryId,
    required this.categoryLabel,
    required this.amountCents,
    required this.percentage,
    required this.color,
  });

  final int categoryId;
  final String categoryLabel;
  final int amountCents;
  final double percentage;
  final Color color;

  double get amount => amountCents / 100.0;
}
