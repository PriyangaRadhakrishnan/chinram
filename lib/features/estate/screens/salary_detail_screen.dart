import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/worker_model.dart';
import '../providers/salary_provider.dart';
import '../providers/worker_provider.dart';

class SalaryDetailScreen extends ConsumerWidget {
  final String salaryId;

  const SalaryDetailScreen({
    super.key,
    required this.salaryId,
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
    final salaryListAsync = ref.watch(salaryListProvider);
    final workersAsync = ref.watch(workerListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: salaryListAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading details...'),
          error: (err, stack) => Center(child: Text('Error loading details: $err')),
          data: (salaries) {
            final salary = salaries.where((s) => s.id == salaryId).firstOrNull;
            if (salary == null) {
              return const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'Record Not Found',
                description: 'The requested salary log could not be found.',
              );
            }

            return workersAsync.when(
              loading: () => const LoadingIndicator(message: 'Resolving worker profile...'),
              error: (err, stack) => Center(child: Text('Error resolving worker: $err')),
              data: (workersList) {
                final worker = workersList.where((w) => w.id == salary.workerId).firstOrNull;
                final workerName = worker?.name ?? 'Deleted Worker';
                final workerGender = worker?.gender ?? WorkerGender.male;

                final isPaid = salary.paymentStatus == 'paid';
                final statusColor = isPaid ? AppColors.success : AppColors.warning;
                final statusBgColor = statusColor.withValues(alpha: 0.1);

                String workedDurationString = '';
                if (salary.calculationMethod == 'attendance') {
                  workedDurationString = '${salary.presentDays} Days';
                } else {
                  workedDurationString = '${salary.durationValue} ${salary.durationUnit.substring(0, 1).toUpperCase()}${salary.durationUnit.substring(1)}';
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Worker details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  workerGender == WorkerGender.male ? Icons.male : Icons.female,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                workerName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              _GenderBadge(gender: workerGender),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  salary.paymentStatus.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Salary summary card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Salary Computation Log',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(height: 32),
                              _DetailRow(label: 'Salary Period', value: salary.period),
                              _DetailRow(label: 'Start Date', value: _formatPrettyDate(salary.startDate)),
                              _DetailRow(label: 'End Date', value: _formatPrettyDate(salary.endDate)),
                              _DetailRow(
                                label: 'Calculation Method',
                                value: salary.calculationMethod == 'attendance' ? 'Automatic (Attendance)' : 'Manual',
                              ),
                              _DetailRow(label: 'Worked Duration', value: workedDurationString),
                              if (salary.calculationMethod == 'attendance')
                                _DetailRow(label: 'Present Days', value: salary.presentDays.toString()),
                              _DetailRow(label: 'Daily Wage Applied', value: '₹${salary.dailyWage.toStringAsFixed(2)}'),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Salary Generated',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '₹${salary.totalSalary.toStringAsFixed(2)}',
                                    style: theme.textTheme.headlineSmall?.copyWith(
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

                      // Audit logs card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Metadata & Auditing',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(height: 32),
                              if (salary.paymentDate != null) ...[
                                _DetailRow(
                                  label: 'Payment Timestamp',
                                  value: '${_formatPrettyDate(salary.paymentDate!)} at ${_formatPrettyTime(salary.paymentTime ?? '00:00:00')}',
                                ),
                              ],
                              _DetailRow(
                                label: 'Created On',
                                value: '${_formatPrettyDate(salary.createdDate)} at ${_formatPrettyTime(salary.createdTime)}',
                              ),
                              _DetailRow(
                                label: 'Last Updated',
                                value: '${_formatPrettyDate(salary.lastUpdatedDate)} at ${_formatPrettyTime(salary.lastUpdatedTime)}',
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

class _GenderBadge extends StatelessWidget {
  final WorkerGender gender;

  const _GenderBadge({required this.gender});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = gender == WorkerGender.male;
    final color = isMale ? AppColors.info : AppColors.accent;
    final bgColor = color.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        gender.label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
