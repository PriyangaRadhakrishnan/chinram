import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/farm_dashboard_data.dart';
import 'farm_income_provider.dart';
import 'farm_expense_provider.dart';
import 'farm_fertilizer_provider.dart';
import 'farm_salary_provider.dart';

String _formatBags(double val) {
  if (val == val.toInt()) {
    return val.toInt().toString();
  }
  return val.toString();
}

final farmDashboardDataProvider = Provider<AsyncValue<FarmDashboardData>>((ref) {
  final incomesAsync = ref.watch(farmIncomeListProvider);
  final expensesAsync = ref.watch(farmExpenseListProvider);
  final salariesAsync = ref.watch(farmSalaryListProvider);
  final chemicalAsync = ref.watch(farmChemicalInventoryProvider);
  final usagesAsync = ref.watch(farmChemicalUsagesProvider);
  final organicAsync = ref.watch(farmOrganicInventoryProvider);

  return incomesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (incomes) {
      return expensesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
        data: (expenses) {
          return salariesAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
            data: (salaries) {
              return chemicalAsync.when(
                loading: () => const AsyncValue.loading(),
                error: (err, stack) => AsyncValue.error(err, stack),
                data: (chemicals) {
                  return usagesAsync.when(
                    loading: () => const AsyncValue.loading(),
                    error: (err, stack) => AsyncValue.error(err, stack),
                    data: (usages) {
                      return organicAsync.when(
                        loading: () => const AsyncValue.loading(),
                        error: (err, stack) => AsyncValue.error(err, stack),
                        data: (organicPurchases) {
                          double totalIncome = 0.0;
                          double totalExpenses = 0.0;
                          double totalSalary = 0.0;
                          double totalFertilizer = 0.0;

                          for (final item in incomes) {
                            totalIncome += item.totalAmount;
                          }

                          for (final item in expenses) {
                            totalExpenses += item.amount;
                          }

                          for (final item in salaries) {
                            totalSalary += item.salaryAmount;
                          }

                          for (final item in chemicals) {
                            totalFertilizer += item.price;
                          }

                          for (final item in organicPurchases) {
                            totalFertilizer += item.price;
                          }

                          final double combinedExpenses = totalExpenses + totalSalary + totalFertilizer;
                          final double netProfit = totalIncome - combinedExpenses;

                          // Compute live remaining chemical stock bags count
                          double fertilizerStock = 0.0;
                          final Map<String, double> stockMap = {};
                          for (final item in chemicals) {
                            stockMap[item.id] = item.initialStock;
                          }
                          for (final usage in usages) {
                            if (stockMap.containsKey(usage.fertilizerId)) {
                              stockMap[usage.fertilizerId] = stockMap[usage.fertilizerId]! - usage.bagsUsed;
                            }
                          }
                          for (final remaining in stockMap.values) {
                            fertilizerStock += remaining;
                          }

                          final now = DateTime.now();
                          final todayStart = DateTime(now.year, now.month, now.day);
                          // Last 7 days and last 30 days (inclusive of today)
                          final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));
                          final thirtyDaysAgo = todayStart.subtract(const Duration(days: 29));

                          double weeklyIncome = 0.0;
                          double weeklyExpenses = 0.0;
                          double monthlyIncome = 0.0;
                          double monthlyExpenses = 0.0;

                          for (final item in incomes) {
                            final itemDay = DateTime(item.date.year, item.date.month, item.date.day);
                            if (itemDay.isAfter(sevenDaysAgo) || itemDay.isAtSameMomentAs(sevenDaysAgo)) {
                              weeklyIncome += item.totalAmount;
                            }
                            if (itemDay.isAfter(thirtyDaysAgo) || itemDay.isAtSameMomentAs(thirtyDaysAgo)) {
                              monthlyIncome += item.totalAmount;
                            }
                          }

                          for (final item in expenses) {
                            final itemDay = DateTime(item.date.year, item.date.month, item.date.day);
                            if (itemDay.isAfter(sevenDaysAgo) || itemDay.isAtSameMomentAs(sevenDaysAgo)) {
                              weeklyExpenses += item.amount;
                            }
                            if (itemDay.isAfter(thirtyDaysAgo) || itemDay.isAtSameMomentAs(thirtyDaysAgo)) {
                              monthlyExpenses += item.amount;
                            }
                          }

                          for (final item in salaries) {
                            final itemDay = DateTime(item.fromDate.year, item.fromDate.month, item.fromDate.day);
                            if (itemDay.isAfter(sevenDaysAgo) || itemDay.isAtSameMomentAs(sevenDaysAgo)) {
                              weeklyExpenses += item.salaryAmount;
                            }
                            if (itemDay.isAfter(thirtyDaysAgo) || itemDay.isAtSameMomentAs(thirtyDaysAgo)) {
                              monthlyExpenses += item.salaryAmount;
                            }
                          }

                          for (final item in chemicals) {
                            final itemDay = DateTime.parse(item.date);
                            final dayOnly = DateTime(itemDay.year, itemDay.month, itemDay.day);
                            if (dayOnly.isAfter(sevenDaysAgo) || dayOnly.isAtSameMomentAs(sevenDaysAgo)) {
                              weeklyExpenses += item.price;
                            }
                            if (dayOnly.isAfter(thirtyDaysAgo) || dayOnly.isAtSameMomentAs(thirtyDaysAgo)) {
                              monthlyExpenses += item.price;
                            }
                          }

                          for (final item in organicPurchases) {
                            final itemDay = DateTime.parse(item.date);
                            final dayOnly = DateTime(itemDay.year, itemDay.month, itemDay.day);
                            if (dayOnly.isAfter(sevenDaysAgo) || dayOnly.isAtSameMomentAs(sevenDaysAgo)) {
                              weeklyExpenses += item.price;
                            }
                            if (dayOnly.isAfter(thirtyDaysAgo) || dayOnly.isAtSameMomentAs(thirtyDaysAgo)) {
                              monthlyExpenses += item.price;
                            }
                          }

                          final double weeklyProfit = weeklyIncome - weeklyExpenses;
                          final double monthlyProfit = monthlyIncome - monthlyExpenses;

                          return AsyncValue.data(FarmDashboardData(
                            cards: [
                              FarmSummaryCardData(
                                title: 'Total Income',
                                value: formatINR(totalIncome),
                                subtitle: 'Updated today',
                                icon: Icons.currency_rupee_outlined,
                              ),
                              FarmSummaryCardData(
                                title: 'Total Expenses',
                                value: formatINR(combinedExpenses),
                                subtitle: 'Updated today',
                                icon: Icons.money_off_outlined,
                              ),
                              FarmSummaryCardData(
                                title: 'Net Profit',
                                value: formatINR(netProfit),
                                subtitle: 'Updated today',
                                icon: Icons.trending_up_outlined,
                              ),
                              FarmSummaryCardData(
                                title: 'Fertilizer Stock',
                                value: '${_formatBags(fertilizerStock)} Bags',
                                subtitle: 'Available in inventory',
                                icon: Icons.warehouse_outlined,
                              ),
                            ],
                            weeklySummary: FarmWeeklyMonthlySummaryData(
                              income: formatINR(weeklyIncome),
                              expenses: formatINR(weeklyExpenses),
                              profit: formatINR(weeklyProfit),
                            ),
                            monthlySummary: FarmWeeklyMonthlySummaryData(
                              income: formatINR(monthlyIncome),
                              expenses: formatINR(monthlyExpenses),
                              profit: formatINR(monthlyProfit),
                            ),
                          ));
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    },
  );
});
