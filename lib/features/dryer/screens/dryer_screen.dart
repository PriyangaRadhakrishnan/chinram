import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../models/dryer_customer_summary.dart';
import '../models/dryer_visit_model.dart';
import '../providers/dryer_provider.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_info_widgets.dart';

class DryerScreen extends ConsumerStatefulWidget {
  const DryerScreen({super.key});

  @override
  ConsumerState<DryerScreen> createState() => _DryerScreenState();
}

class _DryerScreenState extends ConsumerState<DryerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  DryerProduct? _selectedProduct;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedDate != null ||
      _selectedProduct != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
      _selectedProduct = null;
    });
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<DryerCustomerSummary> _applyFilters(
    List<DryerCustomerSummary> summaries,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final queryDigits = query.replaceAll(RegExp(r'\D'), '');

    return summaries.where((summary) {
      if (query.isNotEmpty) {
        final nameMatch = summary.customer.name.toLowerCase().contains(query);
        final phoneTextMatch =
            summary.customer.phoneNumber.toLowerCase().contains(query);
        final customerDigits =
            summary.customer.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final phoneDigitsMatch =
            queryDigits.isNotEmpty && customerDigits.contains(queryDigits);
        if (!nameMatch && !phoneTextMatch && !phoneDigitsMatch) {
          return false;
        }
      }

      if (_selectedDate != null || _selectedProduct != null) {
        final hasMatchingVisit = summary.visits.any((visit) {
          final matchesDate = _selectedDate == null ||
              DryerCalculator.isSameCalendarDay(visit.date, _selectedDate!);
          final matchesProduct =
              _selectedProduct == null || visit.product == _selectedProduct;
          return matchesDate && matchesProduct;
        });
        if (!hasMatchingVisit) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncSummaries = ref.watch(dryerCustomersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dryer/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            avatar: const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text('Customers'),
                            selected: true,
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                            onSelected: (_) {},
                          ),
                          ActionChip(
                            avatar: Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'Other Expenses',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                            ),
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.06),
                            onPressed: () => context.push('/dryer/expenses'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customer Management',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View customers, latest drying visits, and drying charges.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SearchBarWidget(
                        controller: _searchController,
                        hintText: 'Search by customer name or phone...',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedProduct == null,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onSelected: (_) {
                              setState(() {
                                _selectedProduct = null;
                              });
                            },
                          ),
                          ...DryerProduct.values.map((product) {
                            return ChoiceChip(
                              label: Text(product.label),
                              selected: _selectedProduct == product,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedProduct = selected ? product : null;
                                });
                              },
                            );
                          }),
                          OutlinedButton.icon(
                            onPressed: _pickDateFilter,
                            icon: Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: _selectedDate != null
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            label: Text(
                              _selectedDate == null
                                  ? 'Visit Date'
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
                          if (_hasActiveFilters)
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear Filters'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: asyncSummaries.when(
                    loading: () =>
                        const LoadingIndicator(message: 'Loading customers...'),
                    error: (err, stack) => EmptyState(
                      icon: Icons.error_outline,
                      title: 'Error Loading Customers',
                      description: err.toString(),
                      actionLabel: 'Retry',
                      onActionPressed: () =>
                          ref.invalidate(dryerCustomersProvider),
                    ),
                    data: (summaries) {
                      if (summaries.isEmpty) {
                        return const EmptyState(
                          icon: Icons.local_fire_department_outlined,
                          title: 'No Customers Yet',
                          description:
                              'Tap "+ Add Customer" below to register a customer and record their drying visit.',
                        );
                      }

                      final filtered = _applyFilters(summaries);
                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No Matching Customers',
                          description:
                              'No customers match your current search or filter criteria.',
                          actionLabel: 'Clear Filters',
                          onActionPressed: _clearFilters,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(dryerCustomersProvider.notifier).refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final summary = filtered[index];
                            return DryerCustomerCard(
                              summary: summary,
                              onTap: () => context.push(
                                '/dryer/customer/${summary.customer.id}',
                              ),
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
