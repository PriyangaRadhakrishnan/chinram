import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/dashboard_card.dart';
import '../../../shared/widgets/quick_action_card.dart';
import '../../../shared/widgets/recent_activity_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getTodayDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Summary Cards responsiveness
    final summaryCrossAxisCount = context.isDesktop
        ? 3
        : (context.isTablet ? 2 : 1);
    
    // Quick Actions responsiveness
    final actionCrossAxisCount = context.isDesktop
        ? 3
        : (context.isTablet ? 2 : 1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Manager',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTodayDate(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => context.go('/notifications'),
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        radius: 20,
                        child: const Text(
                          'M',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Summary Section Header
              Text(
                'System Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),

              // Summary Cards Grid
              GridView.count(
                crossAxisCount: summaryCrossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  DashboardCard(
                    icon: Icons.attach_money_outlined,
                    title: 'Total Income',
                    value: '\$12,450.00',
                    subtitle: 'Updated today',
                    onTap: () {},
                  ),
                  DashboardCard(
                    icon: Icons.money_off_outlined,
                    title: 'Total Expenses',
                    value: '\$4,120.00',
                    subtitle: 'Updated today',
                    onTap: () {},
                  ),
                  DashboardCard(
                    icon: Icons.trending_up_outlined,
                    title: 'Net Profit',
                    value: '\$8,330.00',
                    subtitle: 'Updated today',
                    onTap: () {},
                  ),
                  DashboardCard(
                    icon: Icons.people_outline,
                    title: 'Workers',
                    value: '24 Active',
                    subtitle: 'On-site',
                    onTap: () {},
                  ),
                  DashboardCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Fertilizer Stock',
                    value: '120 Bags',
                    subtitle: 'Warehouse A',
                    onTap: () {},
                  ),
                  DashboardCard(
                    icon: Icons.check_circle_outline,
                    title: 'Inventory Status',
                    value: 'Healthy',
                    subtitle: 'Stock checked today',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions Section Header
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Grid
              GridView.count(
                crossAxisCount: actionCrossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.8,
                children: [
                  QuickActionCard(
                    icon: Icons.landscape_outlined,
                    title: 'Estates',
                    description: 'Access estate zones and records',
                    onTap: () => context.go('/estate'),
                  ),
                  QuickActionCard(
                    icon: Icons.agriculture_outlined,
                    title: 'Farms',
                    description: 'Access farm cultivations',
                    onTap: () => context.go('/farm'),
                  ),
                  QuickActionCard(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Dryers',
                    description: 'Access dryer allocations',
                    onTap: () => context.go('/dryer'),
                  ),
                  QuickActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Reports',
                    description: 'Access business reports',
                    onTap: () => context.go('/reports'),
                  ),
                  QuickActionCard(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    description: 'Access system preferences',
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity Log
              const RecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }
}
