import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/category_chip.dart';
import '../models/farm_income_model.dart';
import '../providers/farm_income_provider.dart';

class FarmIncomeDetailScreen extends ConsumerWidget {
  final String incomeId;

  const FarmIncomeDetailScreen({
    super.key,
    required this.incomeId,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncList = ref.watch(farmIncomeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (list) {
            final record = list.cast<FarmIncomeModel?>().firstWhere(
                  (r) => r?.id == incomeId,
                  orElse: () => null,
                );

            if (record == null) {
              return const Center(child: Text('Record not found'));
            }

            final isMilk = record.category.toLowerCase() == 'milk';
            final dateLabel = isMilk && record.fromDate != null && record.toDate != null
                ? '${_formatDate(record.fromDate!)} - ${_formatDate(record.toDate!)}'
                : _formatDate(record.date);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CategoryChip(category: record.category),
                          Text(
                            dateLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        record.productName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isMilk) ...[
                        _buildDetailRow(context, 'Collection From Date', _formatDate(record.fromDate!)),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Collection To Date', _formatDate(record.toDate!)),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Total Litres', '${record.quantity.toStringAsFixed(0)} Litres'),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Rate Per Litre', formatINR(record.pricePerUnit)),
                      ] else ...[
                        _buildDetailRow(
                          context, 
                          record.category.toLowerCase() == 'coconut' ? 'Number of Coconuts' : 'Quantity', 
                          '${record.quantity.toStringAsFixed(record.quantity % 1 == 0 ? 0 : 2)} ${record.unit}'
                        ),
                        const Divider(height: 32),
                        _buildDetailRow(
                          context, 
                          record.category.toLowerCase() == 'coconut' ? 'Price Per Coconut' : 'Price Per Unit', 
                          formatINR(record.pricePerUnit)
                        ),
                      ],
                      const Divider(height: 32),
                      _buildDetailRow(
                        context,
                        'Total Amount',
                        formatINR(record.totalAmount),
                        valueStyle: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (record.notes != null) ...[
                        const Divider(height: 32),
                        Text(
                          'Notes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.notes!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
