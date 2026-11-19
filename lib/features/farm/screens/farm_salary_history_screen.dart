import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/farm_salary_model.dart';
import '../providers/farm_salary_provider.dart';

class FarmSalaryHistoryScreen extends ConsumerStatefulWidget {
  const FarmSalaryHistoryScreen({super.key});

  @override
  ConsumerState<FarmSalaryHistoryScreen> createState() => _FarmSalaryHistoryScreenState();
}

class _FarmSalaryHistoryScreenState extends ConsumerState<FarmSalaryHistoryScreen> {
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  void _confirmDelete(FarmSalaryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Salary Record',
        content: 'Are you sure you want to delete this salary record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(farmSalaryListProvider.notifier).deleteSalary(item.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Salary record deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, FarmSalaryModel item) {
    switch (value) {
      case 'view':
        context.push('/farm/salary/detail/${item.id}');
        break;
      case 'edit':
        context.push('/farm/salary/edit/${item.id}');
        break;
      case 'delete':
        _confirmDelete(item);
        break;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatPrettyDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(farmSalaryListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Salary History'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/farm/salary/add'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const LoadingIndicator(message: 'Loading salary history...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading History',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(farmSalaryListProvider),
          ),
          data: (list) {
            final filteredList = list.where((item) {
              if (_searchQuery.isNotEmpty) {
                final work = item.work.toLowerCase();
                final notes = item.notes?.toLowerCase() ?? '';
                final query = _searchQuery.toLowerCase();
                if (!work.contains(query) && !notes.contains(query)) {
                  return false;
                }
              }

              if (_selectedDateRange != null) {
                final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
                final itemStart = DateTime(item.fromDate.year, item.fromDate.month, item.fromDate.day);
                final itemEnd = DateTime(item.toDate.year, item.toDate.month, item.toDate.day);
                if (itemStart.isBefore(start) || itemEnd.isAfter(end)) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Column(
              children: [
                // Filters Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          hintText: 'Search work or notes...',
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: Icon(
                          Icons.date_range,
                          color: _selectedDateRange != null ? Colors.white : null,
                        ),
                        label: Text(
                          _selectedDateRange != null
                              ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                              : 'Filter Date',
                          style: TextStyle(
                            color: _selectedDateRange != null ? Colors.white : null,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedDateRange != null ? Theme.of(context).colorScheme.primary : null,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear Date Filter',
                        ),
                      ],
                    ],
                  ),
                ),

                // Data List
                Expanded(
                  child: filteredList.isEmpty
                      ? const EmptyState(
                          icon: Icons.payments_outlined,
                          title: 'No Salary Records',
                          description: 'Add salary logs using the "+" button below.',
                        )
                      : isDesktopOrTablet
                          ? _buildDesktopTable(context, filteredList)
                          : _buildMobileList(context, filteredList),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<FarmSalaryModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 80.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/farm/salary/detail/${item.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.work,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) => _handleMenuSelection(val, item),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'view', child: Text('View Details')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrettyDate(item.fromDate)} - ${_formatPrettyDate(item.toDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Persons',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.numberOfPersons}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Salary Paid',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatINR(item.salaryAmount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDesktopTable(BuildContext context, List<FarmSalaryModel> list) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 80.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Period')),
                    DataColumn(label: Text('Work Done')),
                    DataColumn(label: Text('Workers')),
                    DataColumn(label: Text('Salary Amount')),
                    DataColumn(label: Text('Notes')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}')),
                        DataCell(Text(item.work, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text('${item.numberOfPersons}')),
                        DataCell(Text(formatINR(item.salaryAmount), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                        DataCell(Text(item.notes != null && item.notes!.isNotEmpty ? item.notes! : '-')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                tooltip: 'View Details',
                                onPressed: () => context.push('/farm/salary/detail/${item.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => context.push('/farm/salary/edit/${item.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(item),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
