import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/attendance_model.dart';
import '../models/worker_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/worker_provider.dart';

final attendanceDetailProvider = FutureProvider.family<AttendanceModel?, String>((ref, date) {
  final service = ref.watch(attendanceServiceProvider);
  return service.getByDate(date);
});

class AttendanceDetailScreen extends ConsumerStatefulWidget {
  final String date;

  const AttendanceDetailScreen({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends ConsumerState<AttendanceDetailScreen> {
  String _searchQuery = '';
  AttendanceStatus? _statusFilter;

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    AttendanceStatus? tempFilter = _statusFilter;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Records',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
                  RadioListTile<AttendanceStatus?>(
                    title: const Text('Present'),
                    value: AttendanceStatus.present,
                    // ignore: deprecated_member_use
                    groupValue: tempFilter,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setBottomSheetState(() {
                        tempFilter = val;
                      });
                    },
                  ),
                  RadioListTile<AttendanceStatus?>(
                    title: const Text('Absent'),
                    value: AttendanceStatus.absent,
                    // ignore: deprecated_member_use
                    groupValue: tempFilter,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setBottomSheetState(() {
                        tempFilter = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = null;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Clear Filters'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = tempFilter;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(attendanceDetailProvider(widget.date));
    final workersAsync = ref.watch(workerListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final hasActiveFilters = _statusFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail: ${_formatPrettyDate(widget.date)}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading details...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Details',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(attendanceDetailProvider(widget.date)),
          ),
          data: (record) {
            if (record == null) {
              return const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'Record Not Found',
                description: 'The requested attendance log could not be found.',
              );
            }

            final workers = workersAsync.value ?? [];

            // Map saved records to display items.
            // Ignore workers that were deleted from Worker Management.
            final displayItems = <_DisplayItem>[];
            for (final rec in record.records) {
              final worker = workers.where((w) => w.id == rec.workerId).firstOrNull;
              if (worker != null) {
                displayItems.add(_DisplayItem(
                  name: worker.name ?? 'Unknown Worker',
                  gender: worker.gender,
                  status: rec.status,
                ));
              }
            }

            // Filter implementation
            final filteredItems = displayItems.where((item) {
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                if (!item.name.toLowerCase().contains(query)) {
                  return false;
                }
              }
              if (_statusFilter != null) {
                if (item.status != _statusFilter) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Stats Bar
                Container(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SummaryStat(label: 'Total Workers', value: record.totalWorkers.toString(), color: AppColors.textPrimary),
                      _SummaryStat(label: 'Present', value: record.presentCount.toString(), color: AppColors.success),
                      _SummaryStat(label: 'Absent', value: record.absentCount.toString(), color: AppColors.error),
                    ],
                  ),
                ),

                // Search & Filter controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          hintText: 'Search workers by name...',
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showFilterBottomSheet(context),
                        icon: Badge(
                          isLabelVisible: hasActiveFilters,
                          child: const Icon(Icons.tune),
                        ),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Responsive list or table
                Expanded(
                  child: filteredItems.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No Matches Found',
                          description: 'No worker records match your search or filter selection.',
                        )
                      : isDesktopOrTablet
                          ? _buildDesktopTable(context, filteredItems)
                          : _buildMobileList(context, filteredItems),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<_DisplayItem> list) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _GenderBadge(gender: item.gender),
                    ],
                  ),
                ),
                _StatusBadge(status: item.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<_DisplayItem> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    minWidth: MediaQuery.of(context).size.width - 64,
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Worker Name')),
                      DataColumn(label: Text('Gender')),
                      DataColumn(label: Text('Attendance Status')),
                    ],
                    rows: list.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          DataCell(_GenderBadge(gender: item.gender)),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _StatusBadge(status: item.status),
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

class _DisplayItem {
  final String name;
  final WorkerGender gender;
  final AttendanceStatus status;

  _DisplayItem({
    required this.name,
    required this.gender,
    required this.status,
  });
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _StatusBadge extends StatelessWidget {
  final AttendanceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = status == AttendanceStatus.present;
    final color = isPresent ? AppColors.success : AppColors.error;
    final bgColor = color.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
