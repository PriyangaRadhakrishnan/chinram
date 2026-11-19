import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/category_provider.dart';

class EstateCategoryListScreen extends ConsumerWidget {
  const EstateCategoryListScreen({super.key});

  IconData _getCategoryIcon(String catName) {
    switch (catName.toLowerCase()) {
      case 'coffee':
        return Icons.coffee_outlined;
      case 'pepper':
        return Icons.eco_outlined;
      case 'cardamom':
        return Icons.grass_outlined;
      case 'areca nut (pakku)':
        return Icons.grain_outlined;
      case 'avocado':
        return Icons.yard_outlined;
      case 'banana':
        return Icons.shopping_basket_outlined;
      case 'clove (kirambu)':
        return Icons.spa_outlined;
      case 'nutmeg (jathika)':
        return Icons.forest_outlined;
      case 'jackfruit':
        return Icons.nature_outlined;
      default:
        return Icons.more_horiz_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncCategories = ref.watch(categoriesFutureProvider);

    final crossAxisCount = context.isDesktop
        ? 4
        : (context.isTablet ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncCategories.when(
          loading: () => const LoadingIndicator(message: 'Loading categories...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Categories',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(categoriesFutureProvider),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const EmptyState(
                icon: Icons.grid_view_outlined,
                title: 'No Categories Available',
                description: 'No categories were found in the database.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estate Income Logging',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a product category to record a new income entry',
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
                      final icon = _getCategoryIcon(category.name);

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
                            if (category.hasSubProducts) {
                              context.push('/estate/income/category/${category.id}/products');
                            } else {
                              final catEscaped = Uri.encodeComponent(category.name);
                              context.push('/estate/income/history?category=$catEscaped&product=$catEscaped');
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
                                    icon,
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
                                        category.hasSubProducts
                                            ? '${category.subProducts.length} sub-products'
                                            : (category.name == 'Others' ? 'Custom logging' : 'Direct logging'),
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
            );
          },
        ),
      ),
    );
  }
}
