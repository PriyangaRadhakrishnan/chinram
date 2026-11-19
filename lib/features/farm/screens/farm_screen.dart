import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';

import '../providers/farm_income_provider.dart';
import '../providers/farm_expense_provider.dart';
import '../providers/farm_dashboard_provider.dart';
import '../providers/farm_salary_provider.dart';

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

class FarmScreen extends ConsumerWidget {
  const FarmScreen({super.key});

  Color _getCardColor(BuildContext context, String title) {
    final theme = Theme.of(context);
    final titleLower = title.toLowerCase();
    if (titleLower.contains('profit') || titleLower.contains('income')) {
      return const Color(0xFF2E7D32); // Success / Green
    } else if (titleLower.contains('expense')) {
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
    
    // Watch dashboard calculation provider
    final asyncDashboard = ref.watch(farmDashboardDataProvider);
    final incomesAsync = ref.watch(farmIncomeListProvider);
    final expensesAsync = ref.watch(farmExpenseListProvider);
    final salariesAsync = ref.watch(farmSalaryListProvider);

    return Scaffold(
      body: asyncDashboard.when(
        loading: () => const LoadingIndicator(message: 'Loading farm data...'),
        error: (err, stack) => SafeArea(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Data',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(farmDashboardDataProvider),
          ),
        ),
        data: (data) {
          // Grid column counts matching Estate Dashboard
          final quickAccessCrossAxisCount = context.isDesktop
              ? 4
              : (context.isTablet ? 3 : 2); // Responsive cards: 2 per row on mobile

          final financialCrossAxisCount = context.isDesktop
              ? 4
              : (context.isTablet ? 3 : 2);

          // Build activities list
          final List<RecentActivityItem> activities = [];
          if (incomesAsync.hasValue) {
            for (final item in incomesAsync.value!) {
              activities.add(RecentActivityItem(
                icon: Icons.attach_money,
                module: '💰 Farm Income',
                description: 'Logged ₹${item.totalAmount.toStringAsFixed(0)} income for ${item.productName}',
                date: _formatPrettyDate(item.date.toString().split(' ')[0]),
                time: _formatPrettyTime(item.id),
                dateTime: _resolveDateTime(item.id, item.date),
                onTap: () => context.push('/farm/income/history?category=${item.category}'),
              ));
            }
          }
          if (expensesAsync.hasValue) {
            for (final item in expensesAsync.value!) {
              activities.add(RecentActivityItem(
                icon: Icons.money_off,
                module: '💸 Farm Expense',
                description: 'Logged ₹${item.amount.toStringAsFixed(0)} expense for ${item.category}',
                date: _formatPrettyDate(item.date.toString().split(' ')[0]),
                time: _formatPrettyTime(item.id),
                dateTime: _resolveDateTime(item.id, item.date),
                onTap: () => context.push(item.category.toLowerCase() == 'milk' 
                    ? '/farm/expenses/history?category=Milk&subCategory=${item.subCategory}' 
                    : '/farm/expenses/history?category=${item.category}'),
              ));
            }
          }
          if (salariesAsync.hasValue) {
            for (final item in salariesAsync.value!) {
              activities.add(RecentActivityItem(
                icon: Icons.payments_outlined,
                module: '💸 Farm Salary',
                description: 'Paid ₹${item.salaryAmount.toStringAsFixed(0)} salary for ${item.work}',
                date: _formatPrettyDate(item.createdDate),
                time: _formatPrettyTime(item.id),
                dateTime: _resolveDateTime(item.id, item.fromDate),
                onTap: () => context.push('/farm/salary/detail/${item.id}'),
              ));
            }
          }

          // Sort by timestamp descending
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
                    'Farm Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time farm production and financial summary.',
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
                        title: 'Farm Income',
                        onTap: () => context.push('/farm/income'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.money_off_outlined,
                        title: 'Farm Expenses',
                        onTap: () => context.push('/farm/expenses'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.payments_outlined,
                        title: 'Farm Salary',
                        onTap: () => context.push('/farm/salary'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.grass_outlined,
                        title: 'Fertilizer',
                        onTap: () => context.push('/farm/fertilizer'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.analytics_outlined,
                        title: 'Reports',
                        onTap: () => context.push('/farm/reports'),
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
                    itemCount: data.cards.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final card = data.cards[index];
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

                  // 4. Recent Farm Activities
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
                            'Recent Farm Activities',
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
                                      'No recent farm activities.',
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
