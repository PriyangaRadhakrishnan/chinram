import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';

class FarmExpenseCategoryItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const FarmExpenseCategoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class FarmExpenseCategoryScreen extends StatelessWidget {
  const FarmExpenseCategoryScreen({super.key});

  static const List<FarmExpenseCategoryItem> categories = [
    FarmExpenseCategoryItem(
      id: 'coconut',
      name: 'Coconut (Kai Vettu)',
      description: 'Log coconut harvesting expenses & worker wages',
      icon: Icons.park_outlined,
    ),
    FarmExpenseCategoryItem(
      id: 'milk',
      name: 'Milk Expenses',
      description: 'Log feed, grass, doctor, and other dairy expenses',
      icon: Icons.water_drop_outlined,
    ),
    FarmExpenseCategoryItem(
      id: 'mango',
      name: 'Mango Expenses',
      description: 'Log mango cultivation & maintenance expenses',
      icon: Icons.spa_outlined,
    ),
    FarmExpenseCategoryItem(
      id: 'others',
      name: 'Others',
      description: 'Log fence, repairs, water tank, & custom expenses',
      icon: Icons.more_horiz_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crossAxisCount = context.isDesktop
        ? 4
        : (context.isTablet ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Expense Logging',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an expense category to log or view record history',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: context.isDesktop ? 1.6 : 2.5,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (category.id == 'milk') {
                          context.push('/farm/expenses/milk');
                        } else if (category.id == 'coconut') {
                          context.push('/farm/expenses/history?category=Coconut');
                        } else if (category.id == 'mango') {
                          context.push('/farm/expenses/history?category=Mango');
                        } else {
                          context.push('/farm/expenses/history?category=Others');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category.icon,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    category.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    category.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
