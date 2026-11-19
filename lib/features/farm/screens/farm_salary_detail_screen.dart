import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/farm_salary_provider.dart';

class FarmSalaryDetailScreen extends ConsumerWidget {
  final String salaryId;

  const FarmSalaryDetailScreen({
    super.key,
    required this.salaryId,
  });

  String _formatPrettyDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatPrettyDateStr(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return _formatPrettyDate(parsed);
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(farmSalaryListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Details'),
        centerTitle: true,
      ),
      body: listAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading details...'),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (list) {
          final record = list.where((item) => item.id == salaryId).firstOrNull;
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
                        Text(
                          record.work,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Period: ${_formatPrettyDate(record.fromDate)} - ${_formatPrettyDate(record.toDate)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const Divider(height: 32),
                        _buildDetailRow('Work Done', record.work, isBold: true),
                        _buildDetailRow('Number of Persons', '${record.numberOfPersons} Workers'),
                        _buildDetailRow('Total Cost', formatINR(record.salaryAmount), isBold: true, valueColor: theme.colorScheme.primary),
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
                        Text('Created: ${_formatPrettyDateStr(record.createdDate)} at ${_formatPrettyTime(record.createdTime)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Last Updated: ${_formatPrettyDateStr(record.lastUpdatedDate)} at ${_formatPrettyTime(record.lastUpdatedTime)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
