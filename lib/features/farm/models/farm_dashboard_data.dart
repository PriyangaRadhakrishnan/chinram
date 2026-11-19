import 'package:flutter/material.dart';

class FarmSummaryCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const FarmSummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

class FarmWeeklyMonthlySummaryData {
  final String income;
  final String expenses;
  final String profit;

  const FarmWeeklyMonthlySummaryData({
    required this.income,
    required this.expenses,
    required this.profit,
  });
}

class FarmDashboardData {
  final List<FarmSummaryCardData> cards;
  final FarmWeeklyMonthlySummaryData weeklySummary;
  final FarmWeeklyMonthlySummaryData monthlySummary;

  const FarmDashboardData({
    required this.cards,
    required this.weeklySummary,
    required this.monthlySummary,
  });
}
