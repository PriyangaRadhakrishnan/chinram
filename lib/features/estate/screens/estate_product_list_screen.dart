import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/estate_category_model.dart';
import '../providers/category_provider.dart';

class EstateProductListScreen extends ConsumerWidget {
  final String categoryId;

  const EstateProductListScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncCategories = ref.watch(categoriesFutureProvider);

    final crossAxisCount = context.isDesktop
        ? 3
        : (context.isTablet ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Product'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncCategories.when(
          loading: () => const LoadingIndicator(message: 'Loading products...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Products',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(categoriesFutureProvider),
          ),
          data: (categories) {
            final category = categories.cast<EstateCategoryModel?>().firstWhere(
                  (c) => c?.id == categoryId,
                  orElse: () => null,
                );

            if (category == null || !category.hasSubProducts) {
              return const EmptyState(
                icon: Icons.grid_view_outlined,
                title: 'No Products Found',
                description: 'No sub-products were found for this category.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a specific variety of ${category.name} to log income',
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
                      childAspectRatio: context.isDesktop ? 2.0 : 3.0,
                    ),
                    itemCount: category.subProducts.length,
                    itemBuilder: (context, index) {
                      final product = category.subProducts[index];

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
                            final catEscaped = Uri.encodeComponent(category.name);
                            final prodEscaped = Uri.encodeComponent(product);
                            context.push('/estate/income/history?category=$catEscaped&product=$prodEscaped');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.label_outline,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    product,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                  size: 20,
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
