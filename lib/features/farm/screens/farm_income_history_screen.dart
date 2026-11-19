import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/farm_income_model.dart';
import '../providers/farm_income_provider.dart';

class FarmIncomeHistoryScreen extends ConsumerStatefulWidget {
  final String category;

  const FarmIncomeHistoryScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<FarmIncomeHistoryScreen> createState() => _FarmIncomeHistoryScreenState();
}

class _FarmIncomeHistoryScreenState extends ConsumerState<FarmIncomeHistoryScreen> {
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

  void _confirmDelete(FarmIncomeModel item) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Income Record',
        content: 'Are you sure you want to delete this income record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(farmIncomeListProvider.notifier).deleteIncome(item.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Income record deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, FarmIncomeModel item) {
    switch (value) {
      case 'view':
        context.push('/farm/income/detail/${item.id}');
        break;
      case 'edit':
        context.push('/farm/income/edit/${item.id}');
        break;
      case 'delete':
        _confirmDelete(item);
        break;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(farmIncomeListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} History'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final catEscaped = Uri.encodeComponent(widget.category);
          context.push('/farm/income/add?category=$catEscaped');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const LoadingIndicator(message: 'Loading history...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading History',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(farmIncomeListProvider),
          ),
          data: (list) {
            final categoryFilteredList = list.where((item) {
              return item.category.toLowerCase() == widget.category.toLowerCase();
            }).toList();

            final filteredList = categoryFilteredList.where((item) {
              if (_searchQuery.isNotEmpty) {
                final notes = item.notes?.toLowerCase() ?? '';
                final productName = item.productName.toLowerCase();
                final query = _searchQuery.toLowerCase();
                if (!notes.contains(query) && !productName.contains(query)) {
                  return false;
                }
              }

              if (_selectedDateRange != null) {
                final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
                
                // For milk, check if overlaps with selected date range or if date falls inside
                final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
                if (item.fromDate != null && item.toDate != null) {
                  final from = DateTime(item.fromDate!.year, item.fromDate!.month, item.fromDate!.day);
                  final to = DateTime(item.toDate!.year, item.toDate!.month, item.toDate!.day);
                  // Check if [from, to] overlaps with [start, end]
                  if (to.isBefore(start) || from.isAfter(end)) {
                    return false;
                  }
                } else {
                  if (itemDate.isBefore(start) || itemDate.isAfter(end)) {
                    return false;
                  }
                }
              }

              return true;
            }).toList();

            filteredList.sort((a, b) => b.date.compareTo(a.date));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SearchBarWidget(
                              hintText: 'Search notes or products...',
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: Text(
                              _selectedDateRange == null
                                  ? 'Filter Date'
                                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearDateFilter,
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear Date Filter'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: categoryFilteredList.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_outlined,
                          title: 'No History',
                          description: 'No income records found for this category.',
                        )
                      : filteredList.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches',
                              description: 'No income records match the search/filters.',
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

  Widget _buildMobileList(BuildContext context, List<FarmIncomeModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isMilk = item.category.toLowerCase() == 'milk';
        
        final dateLabel = isMilk && item.fromDate != null && item.toDate != null
            ? '${_formatDate(item.fromDate!)} - ${_formatDate(item.toDate!)}'
            : _formatDate(item.date);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CategoryChip(category: item.category),
                    Row(
                      children: [
                        Text(
                          dateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (val) => _handleMenuSelection(val, item),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.productName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity.toStringAsFixed(0)} ${item.unit} × ${formatINR(item.pricePerUnit)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      formatINR(item.totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<FarmIncomeModel> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date / Period')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Product Name')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Price/Unit')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Notes')),
              DataColumn(label: Text('Actions')),
            ],
            rows: list.map((item) {
              final isMilk = item.category.toLowerCase() == 'milk';
              final dateLabel = isMilk && item.fromDate != null && item.toDate != null
                  ? '${_formatDate(item.fromDate!)} - ${_formatDate(item.toDate!)}'
                  : _formatDate(item.date);

              return DataRow(
                cells: [
                  DataCell(Text(dateLabel)),
                  DataCell(CategoryChip(category: item.category)),
                  DataCell(Text(item.productName)),
                  DataCell(Text(item.quantity.toStringAsFixed(0))),
                  DataCell(Text(item.unit)),
                  DataCell(Text(formatINR(item.pricePerUnit))),
                  DataCell(Text(
                    formatINR(item.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    item.notes ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (val) => _handleMenuSelection(val, item),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
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
    );
  }
}
