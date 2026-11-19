import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/weekly_expense_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseListAsync = ref.watch(weeklyExpenseListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Expense Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: expenseListAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading details...'),
          error: (err, stack) => Center(child: Text('Error loading details: $err')),
          data: (expenses) {
            final expense = expenses.where((e) => e.id == expenseId).firstOrNull;
            if (expense == null) {
              return const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'Record Not Found',
                description: 'The requested other expense log could not be found.',
              );
            }

            final categoryDisplay = expense.category == 'Others'
                ? '${expense.category} (${expense.customCategoryName ?? 'Custom'})'
                : expense.category;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.money_off,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            categoryDisplay,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detail Fields Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Other Expense Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 32),
                          _DetailRow(label: 'Date', value: _formatPrettyDate(expense.date)),
                          _DetailRow(label: 'Category', value: expense.category),
                          if (expense.category == 'Others' && expense.customCategoryName != null)
                            _DetailRow(label: 'Custom Category', value: expense.customCategoryName!),
                          _DetailRow(label: 'Amount (₹)', value: '₹${expense.amount.toStringAsFixed(2)}'),
                          _DetailRow(label: 'Notes', value: expense.notes ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Audit Logs Card
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
                            value: '${_formatPrettyDate(expense.createdDate)} at ${_formatPrettyTime(expense.createdTime)}',
                          ),
                          _DetailRow(
                            label: 'Last Updated',
                            value: '${_formatPrettyDate(expense.lastUpdatedDate)} at ${_formatPrettyTime(expense.lastUpdatedTime)}',
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
