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
import '../models/farm_expense_model.dart';
import '../providers/farm_expense_provider.dart';

class FarmExpenseHistoryScreen extends ConsumerStatefulWidget {
  final String category;
  final String? subCategory;

  const FarmExpenseHistoryScreen({
    super.key,
    required this.category,
    this.subCategory,
  });

  @override
  ConsumerState<FarmExpenseHistoryScreen> createState() => _FarmExpenseHistoryScreenState();
}

class _FarmExpenseHistoryScreenState extends ConsumerState<FarmExpenseHistoryScreen> {
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

  void _confirmDelete(FarmExpenseModel item) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Expense Record',
        content: 'Are you sure you want to delete this expense record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(farmExpenseListProvider.notifier).deleteExpense(item.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense record deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, FarmExpenseModel item) {
    switch (value) {
      case 'view':
        context.push('/farm/expenses/detail/${item.id}');
        break;
      case 'edit':
        context.push('/farm/expenses/edit/${item.id}');
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
    final asyncList = ref.watch(farmExpenseListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    final isMilk = widget.category.toLowerCase() == 'milk';
    final title = isMilk && widget.subCategory != null
        ? 'Milk - ${widget.subCategory} History'
        : '${widget.category} Expenses';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final catEscaped = Uri.encodeComponent(widget.category);
          final subCatEscaped = widget.subCategory != null ? Uri.encodeComponent(widget.subCategory!) : '';
          context.push('/farm/expenses/add?category=$catEscaped&subCategory=$subCatEscaped');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const LoadingIndicator(message: 'Loading history...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading History',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(farmExpenseListProvider),
          ),
          data: (list) {
            final categoryFilteredList = list.where((item) {
              final matchesCategory = item.category.toLowerCase() == widget.category.toLowerCase();
              if (!matchesCategory) return false;
              if (isMilk && widget.subCategory != null) {
                return item.subCategory?.toLowerCase() == widget.subCategory!.toLowerCase();
              }
              return true;
            }).toList();

            final filteredList = categoryFilteredList.where((item) {
              if (_searchQuery.isNotEmpty) {
                final notes = item.notes?.toLowerCase() ?? '';
                final productName = item.productName?.toLowerCase() ?? '';
                final query = _searchQuery.toLowerCase();
                if (!notes.contains(query) && !productName.contains(query)) {
                  return false;
                }
              }

              if (_selectedDateRange != null) {
                final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
                final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
                if (itemDate.isBefore(start) || itemDate.isAfter(end)) {
                  return false;
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
                              hintText: 'Search notes or details...',
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
                          description: 'No expense records found for this section.',
                        )
                      : filteredList.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches',
                              description: 'No expense records match the search/filters.',
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

  Widget _buildMobileList(BuildContext context, List<FarmExpenseModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final formattedDate = _formatDate(item.date);
        
        String desc = '';
        if (item.category.toLowerCase() == 'coconut') {
          final vettuStr = item.vettuWorkersCount != null ? 'Vettu: ${item.vettuWorkersCount} workers' : '';
          final chithuStr = item.chithuWorkersCount != null ? 'Chithu: ${item.chithuWorkersCount} workers' : '';
          desc = '$vettuStr, $chithuStr'.trim();
        } else if (item.category.toLowerCase() == 'milk') {
          if (item.subCategory?.toLowerCase() == 'feed' || item.subCategory?.toLowerCase() == 'grass') {
            desc = '${item.productName ?? ""} (${item.quantity?.toStringAsFixed(0)} units)';
          } else {
            desc = item.notes ?? 'Doctor/Other expenses';
          }
        } else if (item.category.toLowerCase() == 'mango') {
          desc = item.notes ?? 'Mango expense';
        } else {
          desc = item.productName ?? item.notes ?? 'Other expense';
        }

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
                    CategoryChip(category: item.subCategory ?? item.category),
                    Row(
                      children: [
                        Text(
                          formattedDate,
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
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatINR(item.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD32F2F), // Red for expenses
                      ),
                    ),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty && item.category.toLowerCase() != 'mango' && item.subCategory?.toLowerCase() != 'doctor') ...[
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

  Widget _buildDesktopTable(BuildContext context, List<FarmExpenseModel> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Sub-Category')),
              DataColumn(label: Text('Details / Purpose')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Notes')),
              DataColumn(label: Text('Actions')),
            ],
            rows: list.map((item) {
              final formattedDate = _formatDate(item.date);
              
              String details = '';
              if (item.category.toLowerCase() == 'coconut') {
                details = 'Vettu: ${item.vettuWorkersCount ?? 0}, Chithu: ${item.chithuWorkersCount ?? 0}';
              } else if (item.category.toLowerCase() == 'milk') {
                details = item.productName ?? 'Doctor/Others';
              } else {
                details = item.productName ?? 'Cultivation/Others';
              }

              return DataRow(
                cells: [
                  DataCell(Text(formattedDate)),
                  DataCell(CategoryChip(category: item.category)),
                  DataCell(Text(item.subCategory ?? '-')),
                  DataCell(Text(details)),
                  DataCell(Text(
                    formatINR(item.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
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
