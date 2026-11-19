import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/manager_salary_model.dart';
import '../providers/salary_provider.dart';
import '../providers/manager_salary_provider.dart';

class SalaryHistoryScreen extends ConsumerStatefulWidget {
  const SalaryHistoryScreen({super.key});

  @override
  ConsumerState<SalaryHistoryScreen> createState() => _SalaryHistoryScreenState();
}

class _SalaryHistoryScreenState extends ConsumerState<SalaryHistoryScreen> {
  String _managerSearchQuery = '';
  final _managerSearchController = TextEditingController();
  DateTimeRange? _managerDateFilterRange;

  @override
  void dispose() {
    _managerSearchController.dispose();
    super.dispose();
  }

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPrettyDateTime(String dateTimeStr) {
    try {
      final parts = dateTimeStr.split(' ');
      if (parts.length < 2) return dateTimeStr;
      
      final parsed = DateTime.parse(parts[0]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formattedDate = '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
      
      final timeParts = parts[1].split(':');
      final formattedTime = timeParts.length >= 2 ? '${timeParts[0]}:${timeParts[1]}' : parts[1];
      
      return '$formattedDate, $formattedTime';
    } catch (_) {
      return dateTimeStr;
    }
  }

  void _selectManagerDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _managerDateFilterRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _managerDateFilterRange = picked;
      });
    }
  }

  void _clearManagerFilters() {
    setState(() {
      _managerSearchQuery = '';
      _managerSearchController.clear();
      _managerDateFilterRange = null;
    });
  }

  void _confirmDeleteManager(ManagerSalaryModel record) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Manager Told Salary',
        content: 'Are you sure you want to delete this Manager Told Salary record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(managerSalaryListProvider.notifier).deleteManagerSalary(record.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Manager Told Salary record deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, ManagerSalaryModel record) {
    switch (value) {
      case 'view':
        context.push('/estate/salary/manager/detail/${record.id}');
        break;
      case 'edit':
        context.push('/estate/salary/manager/edit/${record.id}');
        break;
      case 'delete':
        _confirmDeleteManager(record);
        break;
    }
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  @override
  Widget build(BuildContext context) {
    final summariesAsync = ref.watch(salaryPeriodSummariesProvider);
    final managerSalariesAsync = ref.watch(managerSalaryListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salary Management'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Salary Configuration',
              onPressed: () => context.push('/estate/salary/config'),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Worker Salary'),
              Tab(text: 'Manager Told Salary'),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'managerSalaryFab',
              onPressed: () => context.push('/estate/salary/manager/add'),
              icon: const Icon(Icons.add),
              label: const Text('Manager Told Salary'),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'generateSalaryFab',
              onPressed: () => context.push('/estate/salary/add'),
              icon: const Icon(Icons.add),
              label: const Text('Generate Salary'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Worker Salary Summaries
            SafeArea(
              child: summariesAsync.when(
                loading: () => const LoadingIndicator(message: 'Loading worker salary history...'),
                error: (err, stack) => Center(child: Text('Error loading history: $err')),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No Salaries Found',
                      description: 'Configure Daily Wages and tap Generate Salary to create logs.',
                    );
                  }

                  return isDesktopOrTablet
                      ? _buildWorkerDesktopTable(context, list)
                      : _buildWorkerMobileList(context, list);
                },
              ),
            ),

            // Tab 2: Manager Salary History
            SafeArea(
              child: managerSalariesAsync.when(
                loading: () => const LoadingIndicator(message: 'Loading manager salary history...'),
                error: (err, stack) => Center(child: Text('Error loading manager history: $err')),
                data: (rawList) {
                  // Apply Search & Filter
                  final filteredList = rawList.where((item) {
                    if (_managerSearchQuery.isNotEmpty) {
                      final q = _managerSearchQuery.toLowerCase();
                      if (!item.fromDate.contains(q) && !item.toDate.contains(q)) {
                        return false;
                      }
                    }

                    if (_managerDateFilterRange != null) {
                      final recFrom = DateTime.tryParse(item.fromDate);
                      final recTo = DateTime.tryParse(item.toDate);
                      if (recFrom != null && recTo != null) {
                        final filterStart = _managerDateFilterRange!.start;
                        final filterEnd = _managerDateFilterRange!.end;
                        if (!_isWithinRange(recFrom, filterStart, filterEnd) && 
                            !_isWithinRange(recTo, filterStart, filterEnd)) {
                          return false;
                        }
                      }
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Search & Filter controls
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SearchBarWidget(
                                controller: _managerSearchController,
                                hintText: 'Search by date (yyyy-MM-dd)...',
                                onChanged: (val) {
                                  setState(() {
                                    _managerSearchQuery = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: _selectManagerDateRange,
                              icon: const Icon(Icons.filter_list),
                              tooltip: 'Filter by Date Range',
                            ),
                            if (_managerSearchQuery.isNotEmpty || _managerDateFilterRange != null)
                              IconButton(
                                onPressed: _clearManagerFilters,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear Filters',
                              ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: filteredList.isEmpty
                            ? const EmptyState(
                                icon: Icons.payments_outlined,
                                title: 'No Manager Told Salaries Found',
                                description: 'Add Manager Told Salary records to display logs.',
                              )
                            : isDesktopOrTablet
                                ? _buildManagerDesktopTable(context, filteredList)
                                : _buildManagerMobileList(context, filteredList),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerMobileList(BuildContext context, List<SalaryPeriodSummary> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 150.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final summary = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => context.push('/estate/salary/period/${summary.period}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        summary.period,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated on ${_formatPrettyDate(summary.generatedDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: 'Total Workers', value: summary.totalWorkers.toString(), color: AppColors.textPrimary),
                      _StatItem(label: 'Total Generated', value: '₹${summary.totalSalary.toStringAsFixed(0)}', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: 'Paid (Workers)', value: '${summary.paidCount} (₹${summary.paidAmount.toStringAsFixed(0)})', color: AppColors.success),
                      _StatItem(label: 'Pending (Workers)', value: '${summary.pendingCount} (₹${summary.pendingAmount.toStringAsFixed(0)})', color: AppColors.warning),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Last Updated: ${_formatPrettyDateTime(summary.lastUpdated)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkerDesktopTable(BuildContext context, List<SalaryPeriodSummary> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 150.0),
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
                      DataColumn(label: Text('Salary Period')),
                      DataColumn(label: Text('Generated Date')),
                      DataColumn(label: Text('Total Workers')),
                      DataColumn(label: Text('Total Salary')),
                      DataColumn(label: Text('Paid Count/Amt')),
                      DataColumn(label: Text('Pending Count/Amt')),
                      DataColumn(label: Text('Last Updated')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((summary) {
                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/salary/period/${summary.period}'),
                        cells: [
                          DataCell(Text(
                            summary.period,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          )),
                          DataCell(Text(_formatPrettyDate(summary.generatedDate))),
                          DataCell(Text(summary.totalWorkers.toString())),
                          DataCell(Text('₹${summary.totalSalary.toStringAsFixed(2)}')),
                          DataCell(Text(
                            '${summary.paidCount} (₹${summary.paidAmount.toStringAsFixed(0)})',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            '${summary.pendingCount} (₹${summary.pendingAmount.toStringAsFixed(0)})',
                            style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            _formatPrettyDateTime(summary.lastUpdated),
                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          )),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => context.push('/estate/salary/period/${summary.period}'),
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

  Widget _buildManagerMobileList(BuildContext context, List<ManagerSalaryModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 150.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${record.weeklySalary.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) => _handleMenuSelection(val, record),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'view', child: Text('View Details')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(label: 'From Date', value: _formatPrettyDate(record.fromDate), color: AppColors.textPrimary),
                    _StatItem(label: 'To Date', value: _formatPrettyDate(record.toDate), color: AppColors.textPrimary),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Created: ${_formatPrettyDate(record.createdDate)}, ${_formatPrettyTime(record.createdTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagerDesktopTable(BuildContext context, List<ManagerSalaryModel> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 150.0),
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
                      DataColumn(label: Text('From Date')),
                      DataColumn(label: Text('To Date')),
                      DataColumn(label: Text('Weekly Salary')),
                      DataColumn(label: Text('Created Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((record) {
                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/salary/manager/detail/${record.id}'),
                        cells: [
                          DataCell(Text(_formatPrettyDate(record.fromDate))),
                          DataCell(Text(_formatPrettyDate(record.toDate))),
                          DataCell(Text('₹${record.weeklySalary.toStringAsFixed(2)}')),
                          DataCell(Text('${_formatPrettyDate(record.createdDate)}, ${_formatPrettyTime(record.createdTime)}')),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) => _handleMenuSelection(val, record),
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'view', child: Text('View Details')),
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
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

  String _formatPrettyTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
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
        const SizedBox(height: 4),
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
