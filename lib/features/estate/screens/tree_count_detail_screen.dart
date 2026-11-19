import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/tree_count_provider.dart';

class TreeCountDetailScreen extends ConsumerWidget {
  final String recordId;

  const TreeCountDetailScreen({
    super.key,
    required this.recordId,
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
    final listAsync = ref.watch(treeCountListProvider);
    final ledgerMapAsync = ref.watch(treeCountLedgerMapProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tree Count Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: listAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading details...'),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (list) {
            final record = list.where((r) => r.id == recordId).firstOrNull;
            if (record == null) {
              return const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'Record Not Found',
                description: 'The requested tree count log could not be found.',
              );
            }

            final currentCount = ledgerMapAsync.value?[record.id] ?? record.initialCount;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.forest,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            record.treeName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Population: $currentCount Trees',
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

                  // Specifications Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 32),
                          _DetailRow(label: 'Record Date', value: _formatPrettyDate(record.date)),
                          _DetailRow(label: 'Tree Type', value: record.treeName),
                          _DetailRow(label: 'Plot Name', value: record.plotName),
                          _DetailRow(label: 'Initial Count', value: '${record.initialCount} Trees'),
                          _DetailRow(label: 'Current Ledger Count', value: '$currentCount Trees'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Auditing Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metadata & Auditing',
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
