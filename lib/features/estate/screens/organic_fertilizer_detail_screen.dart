import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/organic_fertilizer_provider.dart';

class OrganicFertilizerDetailScreen extends ConsumerWidget {
  final String organicId;

  const OrganicFertilizerDetailScreen({
    super.key,
    required this.organicId,
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

  String _formatLoads(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(organicFertilizerListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organic Purchase Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: listAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading details...'),
          error: (err, stack) => Center(child: Text('Error loading details: $err')),
          data: (list) {
            final record = list.where((r) => r.id == organicId).firstOrNull;
            if (record == null) {
              return const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'Record Not Found',
                description: 'The requested organic purchase record could not be found.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.local_shipping,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            record.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${record.price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Specifications Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Specifications',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 32),
                          _DetailRow(label: 'Date', value: _formatPrettyDate(record.date)),
                          _DetailRow(label: 'Organic Name', value: record.name),
                          _DetailRow(label: 'Loads Count', value: _formatLoads(record.loads)),
                          _DetailRow(label: 'Unit Type', value: record.unit),
                          _DetailRow(label: 'Price per purchase', value: '₹${record.price.toStringAsFixed(2)}'),
                          _DetailRow(label: 'Total Amount', value: '₹${record.totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Audits Card
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
                            value: '${_formatPrettyDate(record.createdDate)} at ${_formatPrettyTime(record.createdTime)}',
                          ),
                          _DetailRow(
                            label: 'Last Updated',
                            value: '${_formatPrettyDate(record.lastUpdatedDate)} at ${_formatPrettyTime(record.lastUpdatedTime)}',
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
