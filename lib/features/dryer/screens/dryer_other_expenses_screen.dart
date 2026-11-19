import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../models/dryer_expense_model.dart';
import '../providers/dryer_expense_provider.dart';
import '../services/dryer_expense_service.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_expense_card.dart';

class DryerOtherExpensesScreen extends ConsumerStatefulWidget {
  const DryerOtherExpensesScreen({super.key});

  @override
  ConsumerState<DryerOtherExpensesScreen> createState() =>
      _DryerOtherExpensesScreenState();
}

class _DryerOtherExpensesScreenState
    extends ConsumerState<DryerOtherExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedDate != null ||
      _selectedDateRange != null ||
      _selectedCategory != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
      _selectedDateRange = null;
      _selectedCategory = null;
    });
  }

  Future<void> _pickSpecificDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedDateRange = null;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _selectedDate = null;
      });
    }
  }

  void _confirmDelete(DryerExpense expense) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Expense',
        content:
            'Are you sure you want to permanently delete "${expense.category}" from ${DryerCalculator.formatDate(expense.date)}?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          try {
            await ref
                .read(dryerExpensesProvider.notifier)
                .deleteExpense(expense.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete expense: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  List<DryerExpense> _applyFilters(
    List<DryerExpense> expenses,
    String? activeCategory,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    return expenses.where((expense) {
      if (query.isNotEmpty) {
        final categoryMatch = expense.category.toLowerCase().contains(query);
        final notesMatch =
            (expense.notes ?? '').toLowerCase().contains(query);
        if (!categoryMatch && !notesMatch) {
          return false;
        }
      }

      if (_selectedDate != null) {
        if (!DryerCalculator.isSameCalendarDay(expense.date, _selectedDate!)) {
          return false;
        }
      }

      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        final itemDay = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        if (itemDay.isBefore(start) || itemDay.isAfter(end)) {
          return false;
        }
      }

      if (activeCategory != null) {
        if (expense.category.trim().toLowerCase() !=
            activeCategory.trim().toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildScrollableEmptyState(Widget emptyState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 88),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 88).clamp(0.0, double.infinity),
            ),
            child: Center(child: emptyState),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncExpenses = ref.watch(dryerExpensesProvider);
    final hasExpenses = asyncExpenses.asData?.value.isNotEmpty ?? false;

    final availableCategories = asyncExpenses.maybeWhen(
      data: (expenses) => DryerExpenseService.extractUniqueCategories(expenses),
      orElse: () => const <String>[],
    );

    final String? effectiveCategory = _selectedCategory != null &&
            availableCategories.any(
              (c) =>
                  c.toLowerCase() == _selectedCategory!.trim().toLowerCase(),
            )
        ? _selectedCategory
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Expenses'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dryer/expenses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasExpenses) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track and manage operational expenses for the dryer.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SearchBarWidget(
                          controller: _searchController,
                          hintText: 'Search by category or notes...',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickSpecificDate,
                              icon: Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: _selectedDate != null
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              label: Text(
                                _selectedDate == null
                                    ? 'Specific Date'
                                    : DryerCalculator.formatDate(_selectedDate!),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedDate != null
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.08)
                                    : null,
                                side: BorderSide(
                                  color: _selectedDate != null
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickDateRange,
                              icon: Icon(
                                Icons.date_range_outlined,
                                size: 16,
                                color: _selectedDateRange != null
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              label: Text(
                                _selectedDateRange == null
                                    ? 'Date Range'
                                    : '${DryerCalculator.formatDate(_selectedDateRange!.start)} - ${DryerCalculator.formatDate(_selectedDateRange!.end)}',
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedDateRange != null
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.08)
                                    : null,
                                side: BorderSide(
                                  color: _selectedDateRange != null
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (_hasActiveFilters)
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear Filters'),
                              ),
                          ],
                        ),
                        if (availableCategories.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('All Categories'),
                                selected: effectiveCategory == null,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                },
                              ),
                              ...availableCategories.map((category) {
                                final isSelected = effectiveCategory != null &&
                                    effectiveCategory.toLowerCase() ==
                                        category.toLowerCase();
                                return ChoiceChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory =
                                          selected ? category : null;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: asyncExpenses.when(
                    loading: () =>
                        const LoadingIndicator(message: 'Loading expenses...'),
                    error: (err, stack) => _buildScrollableEmptyState(
                      EmptyState(
                        icon: Icons.error_outline,
                        title: 'Error Loading Expenses',
                        description: err.toString(),
                        actionLabel: 'Retry',
                        onActionPressed: () =>
                            ref.invalidate(dryerExpensesProvider),
                      ),
                    ),
                    data: (expenses) {
                      if (expenses.isEmpty) {
                        return _buildScrollableEmptyState(
                          const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Other Expenses Yet',
                            description:
                                'Tap "+ Add Expense" below to record a dryer expense.',
                          ),
                        );
                      }

                      final filtered =
                          _applyFilters(expenses, effectiveCategory);
                      if (filtered.isEmpty) {
                        return _buildScrollableEmptyState(
                          EmptyState(
                            icon: Icons.search_off_outlined,
                            title: 'No Matching Expenses',
                            description:
                                'No expenses match your current search or filter criteria.',
                            actionLabel: 'Clear Filters',
                            onActionPressed: _clearFilters,
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(dryerExpensesProvider.notifier).refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final expense = filtered[index];
                            return DryerExpenseCard(
                              expense: expense,
                              onTap: () => context.push(
                                '/dryer/expenses/detail/${expense.id}',
                              ),
                              onEdit: () => context.push(
                                '/dryer/expenses/edit/${expense.id}',
                              ),
                              onDelete: () => _confirmDelete(expense),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
