import 'package:flutter/material.dart';
import '../models/estate_dashboard_data.dart';
import 'estate_repository.dart';

class MockEstateRepository implements EstateRepository {
  const MockEstateRepository();

  @override
  Future<EstateDashboardData> getDashboardData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    return const EstateDashboardData(
      cards: [
        EstateSummaryCardData(
          title: 'Total Income',
          value: '₹8,250.00',
          subtitle: 'Updated today',
          icon: Icons.currency_rupee_outlined,
        ),
        EstateSummaryCardData(
          title: 'Total Expenses',
          value: '₹2,840.00',
          subtitle: 'Updated today',
          icon: Icons.money_off_outlined,
        ),
        EstateSummaryCardData(
          title: 'Total Salary Expenses',
          value: '₹1,200.00',
          subtitle: 'Paid this month',
          icon: Icons.payments_outlined,
        ),
        EstateSummaryCardData(
          title: 'Total Fertilizer Expenses',
          value: '₹680.00',
          subtitle: 'Purchased this month',
          icon: Icons.shopping_cart_outlined,
        ),
        EstateSummaryCardData(
          title: 'Net Profit',
          value: '₹5,410.00',
          subtitle: 'Updated today',
          icon: Icons.trending_up_outlined,
        ),
        EstateSummaryCardData(
          title: 'Worker Count',
          value: '12 Active',
          subtitle: 'Supervisors and workers on-site',
          icon: Icons.badge_outlined,
        ),
        EstateSummaryCardData(
          title: 'Fertilizer Stock Summary',
          value: '45 Bags',
          subtitle: 'Available in inventory',
          icon: Icons.warehouse_outlined,
        ),
      ],
      weeklySummary: WeeklyMonthlySummaryData(
        income: '₹1,850.00',
        expenses: '₹640.00',
        profit: '₹1,210.00',
      ),
      monthlySummary: WeeklyMonthlySummaryData(
        income: '₹8,250.00',
        expenses: '₹2,840.00',
        profit: '₹5,410.00',
      ),
      chartData: [
        ChartDataPoint(label: 'Jan', value: 2400),
        ChartDataPoint(label: 'Feb', value: 3000),
        ChartDataPoint(label: 'Mar', value: 4300),
        ChartDataPoint(label: 'Apr', value: 4500),
        ChartDataPoint(label: 'May', value: 5410),
      ],
    );
  }
}
