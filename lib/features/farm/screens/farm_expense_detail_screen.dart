import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/category_chip.dart';
import '../models/farm_expense_model.dart';
import '../providers/farm_expense_provider.dart';

class FarmExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;

  const FarmExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncList = ref.watch(farmExpenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (list) {
            final record = list.cast<FarmExpenseModel?>().firstWhere(
                  (r) => r?.id == expenseId,
                  orElse: () => null,
                );

            if (record == null) {
              return const Center(child: Text('Record not found'));
            }

            final formattedDate = _formatDate(record.date);
            final isCoconut = record.category.toLowerCase() == 'coconut';
            final isMilk = record.category.toLowerCase() == 'milk';
            final isFeedOrGrass = isMilk && (record.subCategory?.toLowerCase() == 'feed' || record.subCategory?.toLowerCase() == 'grass');

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
                          CategoryChip(category: record.subCategory ?? record.category),
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
                        record.subCategory != null
                            ? 'Milk - ${record.subCategory} Expense'
                            : '${record.category} Expense Log',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // COCONUT DETAILS BREAKDOWN
                      // ==========================================
                      if (isCoconut) ...[
                        _buildDetailRow(context, 'Vettu Workers Count', '${record.vettuWorkersCount ?? 0} Workers'),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Vettu Workers Amount', formatINR(record.vettuWorkerAmount ?? 0.0)),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Chithu Workers Count', '${record.chithuWorkersCount ?? 0} Workers'),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Chithu Workers Amount', formatINR(record.chithuWorkerAmount ?? 0.0)),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Tea Expense', formatINR(record.teaExpense ?? 0.0)),
                        
                        if (record.otherExpenses != null && record.otherExpenses!.isNotEmpty) ...[
                          const Divider(height: 24),
                          const SizedBox(height: 8),
                          Text(
                            'Other Expenses Breakdown',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: record.otherExpenses!.length,
                            itemBuilder: (context, idx) {
                              final item = record.otherExpenses![idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: _buildDetailRow(context, item.name, formatINR(item.amount)),
                              );
                            },
                          ),
                        ],
                      ]

                      // ==========================================
                      // MILK FEED & GRASS DETAILS
                      // ==========================================
                      else if (isFeedOrGrass) ...[
                        _buildDetailRow(context, 'Product Name', record.productName ?? '-'),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Quantity', '${record.quantity?.toStringAsFixed(0) ?? "0"} ${record.unit ?? ""}'.trim()),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Amount Paid', formatINR(record.amount)),
                      ]

                      // ==========================================
                      // OTHER DETAILS
                      // ==========================================
                      else ...[
                        if (record.productName != null) ...[
                          _buildDetailRow(context, 'Purpose / Details', record.productName!),
                          const Divider(height: 24),
                        ],
                        _buildDetailRow(context, 'Amount Paid', formatINR(record.amount)),
                      ],

                      const Divider(height: 32),
                      _buildDetailRow(
                        context,
                        'Total Calculated Expense',
                        formatINR(record.amount),
                        valueStyle: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFD32F2F), // Red for expenses
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (record.notes != null && record.notes!.isNotEmpty) ...[
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
