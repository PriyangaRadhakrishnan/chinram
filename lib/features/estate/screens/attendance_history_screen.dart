import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPrettyDateTime(String dateStr, String timeStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formattedDate = '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
      
      final timeParts = timeStr.split(':');
      final formattedTime = timeParts.length >= 2 ? '${timeParts[0]}:${timeParts[1]}' : timeStr;
      
      return '$formattedDate, $formattedTime';
    } catch (_) {
      return '$dateStr, $timeStr';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading history...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading History',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(attendanceHistoryProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.history_toggle_off_outlined,
                title: 'No Attendance Records Found',
                description: 'Record and save worker attendance to see historical logs here.',
              );
            }

            return isDesktopOrTablet
                ? _buildDesktopTable(context, list)
                : _buildMobileList(context, list);
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<AttendanceModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/estate/attendance/detail/${record.date}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrettyDate(record.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last Updated: ${_formatPrettyDateTime(record.lastUpdatedDate, record.lastUpdatedTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: 'Total Workers', value: record.totalWorkers.toString(), color: AppColors.textPrimary),
                      _StatItem(label: 'Present', value: record.presentCount.toString(), color: AppColors.success),
                      _StatItem(label: 'Absent', value: record.absentCount.toString(), color: AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<AttendanceModel> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 80,
                  ),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Total Workers')),
                      DataColumn(label: Text('Present Count')),
                      DataColumn(label: Text('Absent Count')),
                      DataColumn(label: Text('Last Updated')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((record) {
                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/attendance/detail/${record.date}'),
                        cells: [
                          DataCell(Text(
                            _formatPrettyDate(record.date),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                          )),
                          DataCell(Text(record.totalWorkers.toString())),
                          DataCell(Text(
                            record.presentCount.toString(),
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            record.absentCount.toString(),
                            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            _formatPrettyDateTime(record.lastUpdatedDate, record.lastUpdatedTime),
                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          )),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => context.push('/estate/attendance/detail/${record.date}'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
