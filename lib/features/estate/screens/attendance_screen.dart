import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/attendance_model.dart';
import '../models/worker_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _searchQuery = '';
  AttendanceStatus? _statusFilter;

  String _formatDisplayDate(DateTime dateTime) {
    const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdayNames[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    return '$weekday, $month ${dateTime.day}, ${dateTime.year}';
  }

  Future<void> _selectDate(BuildContext context, DateTime selectedDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      ref.read(activeAttendanceProvider.notifier).loadDate(picked);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Attendance',
        content: 'Are you sure you want to delete the attendance for the selected date?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(activeAttendanceProvider.notifier).deleteAttendance();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
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
                        'Filter Workers',
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

  Future<void> _saveAttendance() async {
    await ref.read(activeAttendanceProvider.notifier).saveAttendance();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeAttendanceProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final hasActiveFilters = _statusFilter != null;

    // Filter & search implementation
    final filteredItems = state.items.where((item) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Log'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'Attendance Actions',
            onSelected: (val) {
              switch (val) {
                case 'history':
                  context.push('/estate/attendance/history');
                  break;
                case 'edit':
                  ref.read(activeAttendanceProvider.notifier).enableEditing();
                  break;
                case 'delete':
                  _confirmDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Attendance History'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'edit',
                enabled: state.hasAttendanceRecord && !state.isEditing,
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit Attendance'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                enabled: state.hasAttendanceRecord,
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Attendance', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: !isDesktopOrTablet && state.items.isNotEmpty && state.isEditing
          ? FloatingActionButton.extended(
              onPressed: state.isLoading ? null : _saveAttendance,
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : null,
      body: SafeArea(
        child: state.isLoading
            ? const LoadingIndicator(message: 'Loading attendance...')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date selection bar
                  Container(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: isDesktopOrTablet
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Attendance Date',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (!state.isEditing && state.hasAttendanceRecord) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.textSecondary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Read-Only',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontSize: 10,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDisplayDate(state.selectedDate),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _selectDate(context, state.selectedDate),
                                icon: const Icon(Icons.calendar_month),
                                label: const Text('Change Date'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Attendance Date',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (!state.isEditing && state.hasAttendanceRecord) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Read-Only',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDisplayDate(state.selectedDate),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _selectDate(context, state.selectedDate),
                                icon: const Icon(Icons.calendar_month),
                                label: const Text('Change Date'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Search and filter controls
                  if (state.items.isNotEmpty)
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
                          if (isDesktopOrTablet && state.isEditing) ...[
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _saveAttendance,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Attendance'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(180, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Content view
                  Expanded(
                    child: state.items.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline,
                            title: 'No Workers Available',
                            description: 'Ensure active workers are registered in Worker Management first.',
                          )
                        : filteredItems.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_outlined,
                                title: 'No Matches Found',
                                description: 'Try adjusting your search query or status filters.',
                              )
                            : isDesktopOrTablet
                                ? _buildDesktopTable(context, filteredItems, state.isEditing)
                                : _buildMobileList(context, filteredItems, state.isEditing),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<WorkerAttendanceEditItem> list, bool isEditing) {
    final theme = Theme.of(context);
    final notifier = ref.read(activeAttendanceProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
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
                _StatusSelector(
                  status: item.status,
                  onChanged: isEditing
                      ? (newStatus) {
                          notifier.updateStatus(item.workerId, newStatus);
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<WorkerAttendanceEditItem> list, bool isEditing) {
    final notifier = ref.read(activeAttendanceProvider.notifier);

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
                              child: _StatusSelector(
                                status: item.status,
                                onChanged: isEditing
                                    ? (newStatus) {
                                        notifier.updateStatus(item.workerId, newStatus);
                                      }
                                    : null,
                              ),
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

class _StatusSelector extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus>? onChanged;

  const _StatusSelector({
    required this.status,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == AttendanceStatus.present;
    final isAbsent = status == AttendanceStatus.absent;
    final isEnabled = onChanged != null;

    final Color presentBorderColor = isPresent
        ? AppColors.success.withValues(alpha: isEnabled ? 1.0 : 0.4)
        : AppColors.divider;
    final Color presentBgColor = isPresent
        ? AppColors.success.withValues(alpha: isEnabled ? 0.15 : 0.05)
        : Colors.transparent;
    final Color presentTextColor = isPresent
        ? AppColors.success.withValues(alpha: isEnabled ? 1.0 : 0.5)
        : AppColors.textSecondary.withValues(alpha: isEnabled ? 1.0 : 0.4);

    final Color absentBorderColor = isAbsent
        ? AppColors.error.withValues(alpha: isEnabled ? 1.0 : 0.4)
        : AppColors.divider;
    final Color absentBgColor = isAbsent
        ? AppColors.error.withValues(alpha: isEnabled ? 0.15 : 0.05)
        : Colors.transparent;
    final Color absentTextColor = isAbsent
        ? AppColors.error.withValues(alpha: isEnabled ? 1.0 : 0.5)
        : AppColors.textSecondary.withValues(alpha: isEnabled ? 1.0 : 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isEnabled ? () => onChanged!(AttendanceStatus.present) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: presentBgColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              border: Border.all(color: presentBorderColor),
            ),
            child: Text(
              'Present',
              style: TextStyle(
                color: presentTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: isEnabled ? () => onChanged!(AttendanceStatus.absent) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: absentBgColor,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              border: Border.all(color: absentBorderColor),
            ),
            child: Text(
              'Absent',
              style: TextStyle(
                color: absentTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
