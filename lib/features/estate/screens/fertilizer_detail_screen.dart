import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/fertilizer_provider.dart';

class FertilizerDetailScreen extends ConsumerWidget {
  final String id;
  final String type; // 'inventory' | 'usage'

  const FertilizerDetailScreen({
    super.key,
    required this.id,
    required this.type,
  });

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPrettyTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  String _formatBags(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (type == 'inventory') {
      final inventoryAsync = ref.watch(fertilizerInventoryProvider);
      final stockAsync = ref.watch(fertilizerStockMapProvider);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Details'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: inventoryAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading details...'),
            error: (err, stack) => Center(child: Text('Error loading inventory detail: $err')),
            data: (list) {
              final fert = list.where((f) => f.id == id).firstOrNull;
              if (fert == null) {
                return const EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Record Not Found',
                  description: 'The requested inventory record could not be found.',
                );
              }

              final calculatedStock = stockAsync.value?[fert.id] ?? 0.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Card with Stock Summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.warehouse,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fert.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current Stock: ${_formatBags(calculatedStock)} Bags',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pricing Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase & Configuration',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Divider(height: 32),
                            _DetailRow(label: 'Purchase Date', value: _formatPrettyDate(fert.date)),
                            _DetailRow(label: 'Quantity Per Bag', value: '${fert.quantityPerBag} ${fert.unit}'),
                            _DetailRow(label: 'Initial Stock (Bags)', value: '${fert.initialStock} Bags'),
                            _DetailRow(label: 'Price (₹)', value: '₹${fert.price.toStringAsFixed(2)}'),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Price Paid (₹)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '₹${fert.totalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Audit Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Metadata',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Divider(height: 32),
                            _DetailRow(
                              label: 'Created On',
                              value: '${_formatPrettyDate(fert.createdDate)} at ${_formatPrettyTime(fert.createdTime)}',
                            ),
                            _DetailRow(
                              label: 'Last Updated',
                              value: '${_formatPrettyDate(fert.lastUpdatedDate)} at ${_formatPrettyTime(fert.lastUpdatedTime)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Usage details
      final usageAsync = ref.watch(fertilizerUsagesProvider);
      final inventoryAsync = ref.watch(fertilizerInventoryProvider);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Stock Usage Details'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: usageAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading details...'),
            error: (err, stack) => Center(child: Text('Error loading usage detail: $err')),
            data: (usageList) {
              final usage = usageList.where((u) => u.id == id).firstOrNull;
              if (usage == null) {
                return const EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Record Not Found',
                  description: 'The requested usage record could not be found.',
                );
              }

              return inventoryAsync.when(
                loading: () => const LoadingIndicator(message: 'Resolving inventory reference...'),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (inventoryList) {
                  final fert = inventoryList.where((f) => f.id == usage.fertilizerId).firstOrNull;
                  final fertName = fert?.name ?? 'Deleted Fertilizer';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.remove_shopping_cart,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  fertName,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Used: ${_formatBags(usage.bagsUsed)} Bags',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usage Summary',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Divider(height: 32),
                                _DetailRow(label: 'Usage Date', value: _formatPrettyDate(usage.date)),
                                _DetailRow(label: 'Bags Used', value: '${_formatBags(usage.bagsUsed)} Bags'),
                                if (fert != null)
                                  _DetailRow(label: 'Weight Per Bag', value: '${fert.quantityPerBag} ${fert.unit}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Metadata & Audit Trail',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Divider(height: 32),
                                _DetailRow(
                                  label: 'Created On',
                                  value: '${_formatPrettyDate(usage.createdDate)} at ${_formatPrettyTime(usage.createdTime)}',
                                ),
                                _DetailRow(
                                  label: 'Last Updated',
                                  value: '${_formatPrettyDate(usage.lastUpdatedDate)} at ${_formatPrettyTime(usage.lastUpdatedTime)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
