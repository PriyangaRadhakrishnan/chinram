import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/bar_chart_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';

// Imports for providers
import '../providers/estate_income_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/manager_salary_provider.dart';
import '../providers/weekly_expense_provider.dart';
import '../providers/fertilizer_provider.dart';
import '../providers/organic_fertilizer_provider.dart';
import '../providers/tree_count_provider.dart';
import '../providers/tree_cutting_provider.dart';
import '../providers/worker_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/estate_provider.dart';

class RecentActivityItem {
  final IconData icon;
  final String module;
  final String description;
  final String date;
  final String time;
  final VoidCallback onTap;
  final DateTime dateTime;

  const RecentActivityItem({
    required this.icon,
    required this.module,
    required this.description,
    required this.date,
    required this.time,
    required this.onTap,
    required this.dateTime,
  });
}

class EstateScreen extends ConsumerWidget {
  const EstateScreen({super.key});

  Color _getCardColor(BuildContext context, String title) {
    final theme = Theme.of(context);
    final titleLower = title.toLowerCase();
    if (titleLower.contains('profit') || titleLower.contains('income')) {
      return const Color(0xFF2E7D32); // Success / Green
    } else if (titleLower.contains('expense') || titleLower.contains('salary')) {
      return const Color(0xFFD32F2F); // Danger / Red
    }
    return theme.colorScheme.primary;
  }

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = parts[2].padLeft(2, '0');
        final monthIdx = int.tryParse(parts[1]);
        final year = parts[0];
        if (monthIdx != null && monthIdx >= 1 && monthIdx <= 12) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '$day ${months[monthIdx - 1]} $year';
        }
      }
      return dateStr;
    }
  }

  String _formatPrettyTime(String timeStr) {
    final ms = int.tryParse(timeStr);
    if (ms != null && ms > 1000000000000) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  DateTime _getDateTime(String createdDate, String createdTime) {
    try {
      return DateTime.parse('${createdDate}T$createdTime');
    } catch (_) {
      try {
        return DateTime.parse(createdDate);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  DateTime _resolveDateTime(String id, DateTime baseDate) {
    final ms = int.tryParse(id);
    if (ms != null && ms > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return baseDate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch dashboard mock provider (keep existing calculations)
    final asyncData = ref.watch(estateDashboardDataProvider);

    // Watch all live lists for Recent Activities
    final incomesAsync = ref.watch(estateIncomeListProvider);
    final salariesAsync = ref.watch(salaryListProvider);
    final managerSalariesAsync = ref.watch(managerSalaryListProvider);
    final expensesAsync = ref.watch(weeklyExpenseListProvider);
    final fertilizersAsync = ref.watch(fertilizerInventoryProvider);
    final usagesAsync = ref.watch(fertilizerUsagesProvider);
    final organicAsync = ref.watch(organicFertilizerListProvider);
    final treeCountsAsync = ref.watch(treeCountListProvider);
    final treeCuttingsAsync = ref.watch(treeCuttingListProvider);
    final workersAsync = ref.watch(workerListProvider);
    final attendancesAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      body: asyncData.when(
        loading: () => const LoadingIndicator(message: 'Loading estate data...'),
        error: (err, stack) => SafeArea(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Data',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(estateDashboardDataProvider),
          ),
        ),
        data: (data) {
          // Responsive layout grid columns counts
          final quickAccessCrossAxisCount = context.isDesktop
              ? 4
              : (context.isTablet ? 3 : 2);

          final financialCrossAxisCount = context.isDesktop
              ? 4
              : (context.isTablet ? 3 : 2);

          // Filter financial summary cards specifically
          final financialCards = data.cards.where((card) => [
                'Total Income',
                'Total Expenses',
                'Total Salary Expenses',
                'Total Fertilizer Expenses',
                'Net Profit',
              ].contains(card.title)).toList();

          // Build Recent Activities List
          final List<RecentActivityItem> activities = [];

          // 1. Income
          if (incomesAsync.hasValue) {
            for (final item in incomesAsync.value!) {
              activities.add(RecentActivityItem(
                icon: Icons.attach_money,
                module: '💰 Income',
                description: 'Added ₹${item.totalAmount.toStringAsFixed(0)} income for ${item.productName}',
                date: _formatPrettyDate(item.date.toString().split(' ')[0]),
                time: _formatPrettyTime(item.id),
                dateTime: _resolveDateTime(item.id, item.date),
                onTap: () => context.push('/estate/income'),
              ));
            }
          }

          // 2. Salary
          if (salariesAsync.hasValue) {
            for (final item in salariesAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.payments,
                module: '💵 Salary',
                description: 'Generated ${item.period} salary',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/salary'),
              ));
            }
          }

          // 3. Manager Told Salary
          if (managerSalariesAsync.hasValue) {
            for (final item in managerSalariesAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.payments,
                module: '💵 Manager Told Salary',
                description: 'Added Manager Told Salary ₹${item.weeklySalary.toStringAsFixed(0)} for ${_formatPrettyDate(item.fromDate)} to ${_formatPrettyDate(item.toDate)}',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/salary'),
              ));
            }
          }

          // 4. Other Expenses
          if (expensesAsync.hasValue) {
            for (final item in expensesAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.money_off,
                module: '📝 Other Expenses',
                description: 'Added ${item.category} expense ₹${item.amount.toStringAsFixed(0)}',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/expenses'),
              ));
            }
          }

          // 5. Fertilizer Inventory
          if (fertilizersAsync.hasValue) {
            for (final item in fertilizersAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.warehouse,
                module: '🌱 Fertilizer',
                description: 'Added ${item.initialStock} bags of ${item.name}',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/fertilizer'),
              ));
            }
          }

          // 6. Fertilizer Stock Usage
          if (usagesAsync.hasValue && fertilizersAsync.hasValue) {
            for (final item in usagesAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              final fert = fertilizersAsync.value!.where((f) => f.id == item.fertilizerId).firstOrNull;
              final fertName = fert?.name ?? 'fertilizer';
              activities.add(RecentActivityItem(
                icon: Icons.remove_shopping_cart,
                module: '🌱 Fertilizer',
                description: 'Used ${item.bagsUsed} bags of $fertName',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/fertilizer'),
              ));
            }
          }

          // 7. Organic Fertilizer Inventory
          if (organicAsync.hasValue) {
            for (final item in organicAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.grass,
                module: '🌿 Organic Fertilizer',
                description: 'Logged ${item.loads} ${item.unit.toLowerCase()} loads',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/fertilizer'),
              ));
            }
          }

          // 8. Tree Count
          if (treeCountsAsync.hasValue) {
            for (final item in treeCountsAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.nature,
                module: '🌳 Tree Count',
                description: 'Updated ${item.treeName} tree count',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/trees'),
              ));
            }
          }

          // 9. Mara Vettu
          if (treeCuttingsAsync.hasValue) {
            for (final item in treeCuttingsAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.nature_people,
                module: '🪓 Mara Vettu',
                description: 'Recorded cutting of ${item.numberOfTrees ?? 0} ${item.treeName ?? "trees"} trees',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/maravettu'),
              ));
            }
          }

          // 10. Worker Management
          if (workersAsync.hasValue) {
            for (final item in workersAsync.value!) {
              activities.add(RecentActivityItem(
                icon: Icons.badge,
                module: '👷 Worker',
                description: 'Added worker ${item.name ?? "unnamed"}',
                date: _formatPrettyDate(item.id),
                time: _formatPrettyTime(item.id),
                dateTime: _resolveDateTime(item.id, DateTime.now()),
                onTap: () => context.push('/estate/workers'),
              ));
            }
          }

          // 11. Attendance Log
          if (attendancesAsync.hasValue) {
            for (final item in attendancesAsync.value!) {
              final dt = _getDateTime(item.createdDate, item.createdTime);
              activities.add(RecentActivityItem(
                icon: Icons.how_to_reg,
                module: '📅 Attendance',
                description: 'Attendance saved for ${_formatPrettyDate(item.date)}',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.createdTime),
                dateTime: dt,
                onTap: () => context.push('/estate/attendance'),
              ));
            }
          }

          // Sort and limit
          activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          final latestActivities = activities.take(10).toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  Text(
                    'Estate Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time estate health and financial summary',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Quick Access Section
                  Text(
                    'Quick Access',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: quickAccessCrossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _QuickAccessCard(
                        icon: Icons.attach_money_outlined,
                        title: 'Income',
                        onTap: () => context.push('/estate/income'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.payments_outlined,
                        title: 'Salary',
                        onTap: () => context.push('/estate/salary'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.money_off_outlined,
                        title: 'Other Expenses',
                        onTap: () => context.push('/estate/expenses'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.warehouse_outlined,
                        title: 'Fertilizer Management',
                        onTap: () => context.push('/estate/fertilizer'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.nature_outlined,
                        title: 'Tree Count',
                        onTap: () => context.push('/estate/trees'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.nature_people_outlined,
                        title: 'Mara Vettu',
                        onTap: () => context.push('/estate/maravettu'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.badge_outlined,
                        title: 'Worker Management',
                        onTap: () => context.push('/estate/workers'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.how_to_reg_outlined,
                        title: 'Attendance Log',
                        onTap: () => context.push('/estate/attendance'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.analytics_outlined,
                        title: 'Reports',
                        onTap: () => context.push('/estate/reports'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 3. Financial Summary Section
                  Text(
                    'Financial Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: financialCrossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: financialCards.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final card = financialCards[index];
                      return _FinancialSummaryCard(
                        icon: card.icon,
                        title: card.title,
                        amount: card.value,
                        subtitle: card.subtitle,
                        color: _getCardColor(context, card.title),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Weekly & Monthly Summary Section
                  context.isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildFinanceTable(
                                context,
                                'Weekly Summary',
                                data.weeklySummary.income,
                                data.weeklySummary.expenses,
                                data.weeklySummary.profit,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFinanceTable(
                                context,
                                'Monthly Summary',
                                data.monthlySummary.income,
                                data.monthlySummary.expenses,
                                data.monthlySummary.profit,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildFinanceTable(
                              context,
                              'Weekly Summary',
                              data.weeklySummary.income,
                              data.weeklySummary.expenses,
                              data.weeklySummary.profit,
                            ),
                            const SizedBox(height: 16),
                            _buildFinanceTable(
                              context,
                              'Monthly Summary',
                              data.monthlySummary.income,
                              data.monthlySummary.expenses,
                              data.monthlySummary.profit,
                            ),
                          ],
                        ),
                  const SizedBox(height: 28),

                  // Estate Financial Overview Chart Section
                  BarChartWidget(
                    title: 'Estate Financial Overview (Net Profit)',
                    dataPoints: data.chartData.map((dp) {
                      return BarChartDataPoint(label: dp.label, value: dp.value);
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // 4. Recent Estate Activities Card
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Estate Activities',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (latestActivities.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Icon(
                                        Icons.history_toggle_off_outlined,
                                        size: 40,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No recent estate activities',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: latestActivities.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final activity = latestActivities[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    child: Icon(activity.icon, color: theme.colorScheme.primary, size: 20),
                                  ),
                                  title: Text(
                                    activity.description,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    '${activity.module} • ${activity.date} at ${activity.time}',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11),
                                  ),
                                  onTap: activity.onTap,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinanceTable(
    BuildContext context,
    String title,
    String income,
    String expenses,
    String profit,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildFinanceRow(context, 'Income', income, const Color(0xFF2E7D32)),
            const Divider(height: 20),
            _buildFinanceRow(context, 'Expenses', expenses, const Color(0xFFD32F2F)),
            const Divider(height: 20),
            _buildFinanceRow(context, 'Net Profit', profit, theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final String subtitle;
  final Color color;

  const _FinancialSummaryCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color, size: 16),
                ),
                Text(
                  'Updated today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
