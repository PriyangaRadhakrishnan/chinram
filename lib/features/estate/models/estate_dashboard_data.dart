import 'package:flutter/material.dart';

class EstateSummaryCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const EstateSummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

class WeeklyMonthlySummaryData {
  final String income;
  final String expenses;
  final String profit;

  const WeeklyMonthlySummaryData({
    required this.income,
    required this.expenses,
    required this.profit,
  });
}

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });
}

class EstateDashboardData {
  final List<EstateSummaryCardData> cards;
  final WeeklyMonthlySummaryData weeklySummary;
  final WeeklyMonthlySummaryData monthlySummary;
  final List<ChartDataPoint> chartData;

  const EstateDashboardData({
    required this.cards,
    required this.weeklySummary,
    required this.monthlySummary,
    required this.chartData,
  });
}
