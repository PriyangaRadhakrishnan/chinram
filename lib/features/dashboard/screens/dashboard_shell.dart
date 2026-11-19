import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../../authentication/providers/auth_provider.dart';

class DashboardShell extends ConsumerWidget {
  final Widget child;

  const DashboardShell({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/estate')) return 1;
    if (location.startsWith('/farm')) return 2;
    if (location.startsWith('/dryer')) return 3;
    if (location.startsWith('/reports')) return 4;
    if (location.startsWith('/notifications')) return 5;
    if (location.startsWith('/settings')) return 6;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/estate');
        break;
      case 2:
        context.go('/farm');
        break;
      case 3:
        context.go('/dryer');
        break;
      case 4:
        context.go('/reports');
        break;
      case 5:
        context.go('/notifications');
        break;
      case 6:
        context.go('/settings');
        break;
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Sign Out',
        content: 'Are you sure you want to sign out of ChinRam?',
        confirmLabel: 'Sign Out',
        onConfirm: () {
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedIndex = _getSelectedIndex(context);
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? 'Manager';
    final role = authState.user?.role ?? 'Administrator';

    final navDestinations = [
      const NavigationDrawerDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.landscape_outlined),
        selectedIcon: Icon(Icons.landscape),
        label: Text('Estates'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.agriculture_outlined),
        selectedIcon: Icon(Icons.agriculture),
        label: Text('Farms'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.local_fire_department_outlined),
        selectedIcon: Icon(Icons.local_fire_department),
        label: Text('Dryers'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Reports'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications),
        label: Text('Notifications'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];

    Widget userHeader = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            radius: 24,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'M',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );

    // Desktop Layout: Permanent Sidebar
    if (context.isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
              ),
              child: Column(
                children: [
                  userHeader,
                  Expanded(
                    child: NavigationDrawer(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (idx) => _onItemTapped(idx, context),
                      children: [
                        const SizedBox(height: 16),
                        ...navDestinations,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Tablet Layout: NavigationRail
    if (context.isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              labelType: NavigationRailLabelType.all,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    radius: 20,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'M',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => _handleLogout(context, ref),
                    ),
                  ),
                ),
              ),
              destinations: navDestinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: d.label,
                );
              }).toList(),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile Layout: Navigation Drawer
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChinRam'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            userHeader,
            Expanded(
              child: NavigationDrawer(
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) {
                  Navigator.of(context).pop(); // Close drawer
                  _onItemTapped(idx, context);
                },
                children: [
                  const SizedBox(height: 16),
                  ...navDestinations,
                ],
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
