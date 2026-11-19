import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/worker_model.dart';
import '../providers/worker_provider.dart';

class WorkerDetailScreen extends ConsumerWidget {
  final String workerId;

  const WorkerDetailScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncList = ref.watch(workerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (list) {
            final worker = list.cast<WorkerModel?>().firstWhere(
                  (w) => w?.id == workerId,
                  orElse: () => null,
                );

            if (worker == null) {
              return const Center(child: Text('Worker not found'));
            }

            final displayName = (worker.name == null || worker.name!.trim().isEmpty) ? '-' : worker.name!;
            final displayPhone = (worker.phoneNumber == null || worker.phoneNumber!.trim().isEmpty) ? '-' : worker.phoneNumber!;
            final displayNotes = (worker.notes == null || worker.notes!.trim().isEmpty) ? '-' : worker.notes!;

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
                          Text(
                            'Worker Profile',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          _StatusBadge(status: worker.status),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow(context, 'Gender', worker.gender.label),
                      const Divider(height: 32),
                      _buildDetailRow(context, 'Phone Number', displayPhone),
                      const Divider(height: 32),
                      _buildDetailRow(
                        context,
                        'Status',
                        worker.status.label,
                        valueStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: worker.status == WorkerStatus.active
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        displayNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
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

class _StatusBadge extends StatelessWidget {
  final WorkerStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = status == WorkerStatus.active;
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    final bgColor = isActive
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.textSecondary.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
