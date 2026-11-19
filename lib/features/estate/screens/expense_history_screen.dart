import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/weekly_expense_model.dart';
import '../providers/weekly_expense_provider.dart';

class ExpenseHistoryScreen extends ConsumerStatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ConsumerState<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends ConsumerState<ExpenseHistoryScreen> {
  String _searchQuery = '';

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _categoryFilter;

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmDelete(WeeklyExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Other Expense',
        content: 'Are you sure you want to delete this other expense?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(weeklyExpenseListProvider.notifier).deleteExpense(expense.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Other Expense deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, WeeklyExpenseModel expense) {
    switch (value) {
      case 'view':
        context.push('/estate/expenses/detail/${expense.id}');
        break;
      case 'edit':
        context.push('/estate/expenses/edit/${expense.id}');
        break;
      case 'delete':
        _confirmDelete(expense);
        break;
    }
  }

  String _formatDateString(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _selectFilterDate(BuildContext context, bool isStart, StateSetter setBottomSheetState) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setBottomSheetState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    String? tempCategory = _categoryFilter;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Other Expenses',
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

                    // Date range selection
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectFilterDate(context, true, setBottomSheetState),
                            child: Text(tempStart == null ? 'Start Date' : _formatDateString(tempStart)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectFilterDate(context, false, setBottomSheetState),
                            child: Text(tempEnd == null ? 'End Date' : _formatDateString(tempEnd)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown filter
                    const Text('Expense Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      // ignore: deprecated_member_use
                      value: tempCategory,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      hint: const Text('All Categories'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Categories')),
                        DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                        DropdownMenuItem(value: 'Brush Cutter', child: Text('Brush Cutter')),
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                        DropdownMenuItem(value: 'Pest / Insecticide', child: Text('Pest / Insecticide')),
                        DropdownMenuItem(value: 'Others', child: Text('Others')),
                      ],
                      onChanged: (val) {
                        setBottomSheetState(() {
                          tempCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                                _categoryFilter = null;
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
                                _startDate = tempStart;
                                _endDate = tempEnd;
                                _categoryFilter = tempCategory;
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(weeklyExpenseListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final hasActiveFilters = _startDate != null || _endDate != null || _categoryFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Expenses'),
        centerTitle: true,
        actions: [
          if (isDesktopOrTablet)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/estate/expenses/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add Other Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isDesktopOrTablet
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/estate/expenses/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Other Expense'),
            ),
      body: SafeArea(
        child: expensesAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading other expenses...'),
          error: (err, stack) => Center(child: Text('Error loading other expenses: $err')),
          data: (allExpenses) {
            // Filter list
            final filteredExpenses = allExpenses.where((expense) {
              // Search Query
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final categoryName = expense.category == 'Others'
                    ? (expense.customCategoryName ?? 'Others').toLowerCase()
                    : expense.category.toLowerCase();
                final notesText = (expense.notes ?? '').toLowerCase();

                if (!categoryName.contains(query) && !notesText.contains(query)) {
                  return false;
                }
              }

              // Date Range Filter
              if (_startDate != null) {
                try {
                  final expenseDate = DateTime.parse(expense.date);
                  if (expenseDate.isBefore(_startDate!)) return false;
                } catch (_) {}
              }
              if (_endDate != null) {
                try {
                  final expenseDate = DateTime.parse(expense.date);
                  if (expenseDate.isAfter(_endDate!)) return false;
                } catch (_) {}
              }

              // Category Filter
              if (_categoryFilter != null) {
                if (expense.category != _categoryFilter) {
                  return false;
                }
              }

              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (allExpenses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBarWidget(
                            hintText: 'Search by category, notes...',
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

                Expanded(
                  child: allExpenses.isEmpty
                      ? const EmptyState(
                          icon: Icons.money_off_outlined,
                          title: 'No Other Expenses',
                          description: 'No other expenses recorded yet.',
                        )
                      : filteredExpenses.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches Found',
                              description: 'Adjust your search queries or active filters.',
                            )
                          : isDesktopOrTablet
                              ? _buildDesktopTable(context, filteredExpenses)
                              : _buildMobileList(context, filteredExpenses),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<WeeklyExpenseModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final expense = list[index];
        final categoryDisplay = expense.category == 'Others'
            ? '${expense.category} (${expense.customCategoryName ?? ''})'
            : expense.category;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/estate/expenses/detail/${expense.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrettyDate(expense.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) => _handleMenuSelection(val, expense),
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
                      Expanded(
                        child: Text(
                          categoryDisplay,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${expense.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      expense.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<WeeklyExpenseModel> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Expense Category')),
                      DataColumn(label: Text('Notes')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((expense) {
                      final categoryDisplay = expense.category == 'Others'
                          ? '${expense.category} (${expense.customCategoryName ?? ''})'
                          : expense.category;

                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/expenses/detail/${expense.id}'),
                        cells: [
                          DataCell(Text(
                            _formatPrettyDate(expense.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(categoryDisplay)),
                          DataCell(Text(
                            expense.notes ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          )),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) => _handleMenuSelection(val, expense),
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
}
