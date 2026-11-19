import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/category_chip.dart';
import '../models/estate_income_model.dart';
import '../providers/estate_income_provider.dart';

class EstateIncomeDetailScreen extends ConsumerWidget {
  final String incomeId;

  const EstateIncomeDetailScreen({
    super.key,
    required this.incomeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncList = ref.watch(estateIncomeListProvider);

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
            final record = list.cast<EstateIncomeModel?>().firstWhere(
                  (r) => r?.id == incomeId,
                  orElse: () => null,
                );

            if (record == null) {
              return const Center(child: Text('Record not found'));
            }

            final formattedDate = '${record.date.day}/${record.date.month}/${record.date.year}';

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
                            formattedDate,
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
                      if (record.category.toLowerCase() == 'cardamom') ...[
                        _buildDetailRow(context, 'Green Quantity', '${record.greenQuantity ?? 0.0} ${record.unit}'),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Dry Quantity', '${record.dryQuantity ?? 0.0} ${record.unit}'),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Unit', record.unit),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Percent', '${record.percent?.toStringAsFixed(2) ?? "0.00"}%'),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Price Per Unit', formatINR(record.pricePerUnit)),
                      ] else ...[
                        _buildDetailRow(context, 'Quantity', '${record.quantity} ${record.unit}'),
                        const Divider(height: 32),
                        _buildDetailRow(context, 'Price Per Unit', formatINR(record.pricePerUnit)),
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
