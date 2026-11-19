import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/farm_fertilizer_provider.dart';

// Helper for formatting decimal counts
String _formatDecimal(double val) {
  if (val == val.toInt()) {
    return val.toInt().toString();
  }
  return val.toString();
}

String _formatPrettyDate(String dateStr) {
  try {
    final parsed = DateTime.parse(dateStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  } catch (_) {
    return dateStr;
  }
}

// -----------------------------------------------------------------------------
// 1. CHEMICAL FERTILIZER DETAIL SCREEN
// -----------------------------------------------------------------------------
class FarmFertilizerDetailScreen extends ConsumerWidget {
  final String id;
  const FarmFertilizerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncInventory = ref.watch(farmChemicalInventoryProvider);
    final stockMap = ref.watch(farmChemicalStockMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chemical Fertilizer Details'), centerTitle: true),
      body: asyncInventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (list) {
          final record = list.where((item) => item.id == id).firstOrNull;
          if (record == null) {
            return const Center(child: Text('Record not found'));
          }
          final remaining = stockMap[record.id] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Purchased on ${_formatPrettyDate(record.date)}', style: const TextStyle(color: AppColors.textSecondary)),
                        const Divider(height: 32),
                        _buildDetailRow('Remaining Stock', '${_formatDecimal(remaining)} Bags', isBold: true),
                        _buildDetailRow('Initial Stock', '${_formatDecimal(record.initialStock)} Bags'),
                        _buildDetailRow('Quantity Per Bag', '${record.quantityPerBag} ${record.unit}'),
                        _buildDetailRow('Total Cost', formatINR(record.price)),
                        if (record.notes != null && record.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(record.notes!, style: const TextStyle(height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('System Logs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Created: ${_formatPrettyDate(record.createdDate)} at ${record.createdTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Last Updated: ${_formatPrettyDate(record.lastUpdatedDate)} at ${record.lastUpdatedTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. ORGANIC FERTILIZER DETAIL SCREEN
// -----------------------------------------------------------------------------
class FarmOrganicFertilizerDetailScreen extends ConsumerWidget {
  final String id;
  const FarmOrganicFertilizerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncInventory = ref.watch(farmOrganicInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Organic Fertilizer Details'), centerTitle: true),
      body: asyncInventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (list) {
          final record = list.where((item) => item.id == id).firstOrNull;
          if (record == null) {
            return const Center(child: Text('Record not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Purchased on ${_formatPrettyDate(record.date)}', style: const TextStyle(color: AppColors.textSecondary)),
                        const Divider(height: 32),
                        _buildDetailRow('Initial Loads', '${_formatDecimal(record.loads)} Loads', isBold: true),
                        _buildDetailRow('Vehicle Type', record.unit),
                        _buildDetailRow('Total Cost', formatINR(record.price)),
                        if (record.notes != null && record.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(record.notes!, style: const TextStyle(height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('System Logs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Created: ${_formatPrettyDate(record.createdDate)} at ${record.createdTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Last Updated: ${_formatPrettyDate(record.lastUpdatedDate)} at ${record.lastUpdatedTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. CHEMICAL USAGE DETAIL SCREEN
// -----------------------------------------------------------------------------
class FarmFertilizerUsageDetailScreen extends ConsumerWidget {
  final String id;
  const FarmFertilizerUsageDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncUsages = ref.watch(farmChemicalUsagesProvider);
    final asyncInventory = ref.watch(farmChemicalInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chemical Usage Details'), centerTitle: true),
      body: asyncUsages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (list) {
          final record = list.where((item) => item.id == id).firstOrNull;
          if (record == null) {
            return const Center(child: Text('Record not found'));
          }

          final fertilizers = asyncInventory.value ?? [];
          final matchFert = fertilizers.where((item) => item.id == record.fertilizerId).firstOrNull;
          final String fertilizerName = matchFert?.name ?? 'Unknown';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chemical Usage Log', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Logged on ${_formatPrettyDate(record.date)}', style: const TextStyle(color: AppColors.textSecondary)),
                        const Divider(height: 32),
                        _buildDetailRow('Fertilizer Name', fertilizerName, isBold: true),
                        _buildDetailRow('Quantity Used', '${_formatDecimal(record.bagsUsed)} Bags'),
                        if (record.notes != null && record.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(record.notes!, style: const TextStyle(height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('System Logs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Created: ${_formatPrettyDate(record.createdDate)} at ${record.createdTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Last Updated: ${_formatPrettyDate(record.lastUpdatedDate)} at ${record.lastUpdatedTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. HELPER METHOD
// -----------------------------------------------------------------------------

// Helper method to build simple detail lines
Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
