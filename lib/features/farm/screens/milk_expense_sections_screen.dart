import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';

class MilkExpenseSectionItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const MilkExpenseSectionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class MilkExpenseSectionsScreen extends StatelessWidget {
  const MilkExpenseSectionsScreen({super.key});

  static const List<MilkExpenseSectionItem> sections = [
    MilkExpenseSectionItem(
      id: 'Feed',
      name: 'Feed Expenses',
      description: 'Log purchase of cattle feed, sacks, etc.',
      icon: Icons.grain_outlined,
    ),
    MilkExpenseSectionItem(
      id: 'Grass',
      name: 'Grass Expenses',
      description: 'Log purchase of fodder grass, green forage',
      icon: Icons.grass_outlined,
    ),
    MilkExpenseSectionItem(
      id: 'Doctor',
      name: 'Doctor & Medical',
      description: 'Log veterinary visits, vaccines, medicines',
      icon: Icons.local_hospital_outlined,
    ),
    MilkExpenseSectionItem(
      id: 'Others',
      name: 'Others',
      description: 'Log custom milking tools, cleaning, etc.',
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
        title: const Text('Milk Expense Sections'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Milk Expenses',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a dairy-related section to log or view records',
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
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];

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
                        context.push('/farm/expenses/history?category=Milk&subCategory=${section.id}');
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
                                section.icon,
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
                                    section.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    section.description,
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
