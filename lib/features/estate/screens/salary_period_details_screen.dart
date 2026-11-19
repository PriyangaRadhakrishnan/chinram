import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/salary_model.dart';
import '../models/worker_model.dart';
import '../providers/salary_provider.dart';
import '../providers/worker_provider.dart';

class SalaryPeriodDetailsScreen extends ConsumerStatefulWidget {
  final String period;

  const SalaryPeriodDetailsScreen({
    super.key,
    required this.period,
  });

  @override
  ConsumerState<SalaryPeriodDetailsScreen> createState() => _SalaryPeriodDetailsScreenState();
}

class _SalaryPeriodDetailsScreenState extends ConsumerState<SalaryPeriodDetailsScreen> {
  String _searchQuery = '';
  
  // Filters
  String? _statusFilter; // 'paid' | 'pending' | null
  String? _genderFilter; // 'male' | 'female' | null
  String? _methodFilter; // 'attendance' | 'manual' | null

  void _confirmDelete(SalaryModel salary) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Salary',
        content: 'Are you sure you want to delete this salary record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(salaryListProvider.notifier).deleteSalary(salary.id);
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

  void _markAsPaid(SalaryModel salary) async {
    final String nowStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final String timeStr = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";

    final updated = salary.copyWith(
      paymentStatus: 'paid',
      paymentDate: nowStr,
      paymentTime: timeStr,
      lastUpdatedDate: nowStr,
      lastUpdatedTime: timeStr,
    );

    await ref.read(salaryListProvider.notifier).updateSalary(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary marked as Paid'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleMenuSelection(String value, SalaryModel salary) {
    switch (value) {
      case 'view':
        context.push('/estate/salary/detail/${salary.id}');
        break;
      case 'edit':
        context.push('/estate/salary/edit/${salary.id}');
        break;
      case 'pay':
        _markAsPaid(salary);
        break;
      case 'delete':
        _confirmDelete(salary);
        break;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    String? tempStatus = _statusFilter;
    String? tempGender = _genderFilter;
    String? tempMethod = _methodFilter;

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
                          'Filter Salaries',
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
                    
                    // Payment Status
                    const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<String?>(
                      title: const Text('All'),
                      value: null,
                      // ignore: deprecated_member_use
                      groupValue: tempStatus,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempStatus = val),
                    ),
                    RadioListTile<String?>(
                      title: const Text('Paid'),
                      value: 'paid',
                      // ignore: deprecated_member_use
                      groupValue: tempStatus,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempStatus = val),
                    ),
                    RadioListTile<String?>(
                      title: const Text('Pending'),
                      value: 'pending',
                      // ignore: deprecated_member_use
                      groupValue: tempStatus,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempStatus = val),
                    ),
                    const Divider(),

                    // Gender
                    const Text('Worker Gender', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<String?>(
                      title: const Text('All'),
                      value: null,
                      // ignore: deprecated_member_use
                      groupValue: tempGender,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempGender = val),
                    ),
                    RadioListTile<String?>(
                      title: const Text('Male'),
                      value: 'male',
                      // ignore: deprecated_member_use
                      groupValue: tempGender,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempGender = val),
                    ),
                    RadioListTile<String?>(
                      title: const Text('Female'),
                      value: 'female',
                      // ignore: deprecated_member_use
                      groupValue: tempGender,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempGender = val),
                    ),
                    const Divider(),

                    // Calculation Method
                    const Text('Calculation Method', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<String?>(
                      title: const Text('All'),
                      value: null,
                      // ignore: deprecated_member_use
                      groupValue: tempMethod,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempMethod = val),
                    ),
                    RadioListTile<String?>(
                      title: const Text('Attendance'),
                      value: 'attendance',
                      // ignore: deprecated_member_use
                      groupValue: tempMethod,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempMethod = val),
                    ),
                    RadioListTile<String?>(
                      title: const Text('Manual'),
                      value: 'manual',
                      // ignore: deprecated_member_use
                      groupValue: tempMethod,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setBottomSheetState(() => tempMethod = val),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = null;
                                _genderFilter = null;
                                _methodFilter = null;
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
                                _statusFilter = tempStatus;
                                _genderFilter = tempGender;
                                _methodFilter = tempMethod;
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
    final salariesAsync = ref.watch(salaryListProvider);
    final workersAsync = ref.watch(workerListProvider);

    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final hasActiveFilters = _statusFilter != null || _genderFilter != null || _methodFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Salaries: ${widget.period}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: salariesAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading salaries...'),
          error: (err, stack) => Center(child: Text('Error loading salaries: $err')),
          data: (allSalaries) {
            // Filter by selected period name
            final periodSalaries = allSalaries.where((s) => s.period == widget.period).toList();

            return workersAsync.when(
              loading: () => const LoadingIndicator(message: 'Resolving worker profiles...'),
              error: (err, stack) => Center(child: Text('Error resolving workers: $err')),
              data: (workersList) {
                // Filter out records whose workers were deleted from Worker Management
                final List<_ResolvedSalaryItem> resolvedItems = [];
                for (final sal in periodSalaries) {
                  final worker = workersList.where((w) => w.id == sal.workerId).firstOrNull;
                  if (worker != null) {
                    resolvedItems.add(_ResolvedSalaryItem(salary: sal, worker: worker));
                  }
                }

                // Apply search & filter on resolved items
                final filteredItems = resolvedItems.where((item) {
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    if (!(item.worker.name?.toLowerCase().contains(query) ?? false)) {
                      return false;
                    }
                  }

                  if (_statusFilter != null) {
                    if (item.salary.paymentStatus != _statusFilter) {
                      return false;
                    }
                  }

                  if (_genderFilter != null) {
                    if (item.worker.gender.name != _genderFilter) {
                      return false;
                    }
                  }

                  if (_methodFilter != null) {
                    if (item.salary.calculationMethod != _methodFilter) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search & Filter bar
                    if (resolvedItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SearchBarWidget(
                                hintText: 'Search by worker name...',
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
                      child: resolvedItems.isEmpty
                          ? const EmptyState(
                              icon: Icons.assignment_outlined,
                              title: 'No Salaries Generated',
                              description: 'No salaries recorded for this period yet.',
                            )
                          : filteredItems.isEmpty
                              ? const EmptyState(
                                  icon: Icons.search_off_outlined,
                                  title: 'No Matches',
                                  description: 'Try adjusting your search query or filters.',
                                )
                              : isDesktopOrTablet
                                  ? _buildDesktopTable(context, filteredItems)
                                  : _buildMobileList(context, filteredItems),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<_ResolvedSalaryItem> list) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final salary = item.salary;
        final worker = item.worker;

        final isPaid = salary.paymentStatus == 'paid';
        final statusColor = isPaid ? AppColors.success : AppColors.warning;
        final statusBgColor = statusColor.withValues(alpha: 0.1);

        String durationText = '';
        if (salary.calculationMethod == 'attendance') {
          durationText = 'Automatic (${salary.presentDays} Days)';
        } else {
          durationText = 'Manual (${salary.durationValue} ${salary.durationUnit})';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                        worker.name ?? 'Unknown Worker',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            salary.paymentStatus.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (val) => _handleMenuSelection(val, salary),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View Details')),
                            PopupMenuItem(
                              value: 'edit',
                              enabled: !isPaid, // Disabled/Locked if paid
                              child: Text(
                                'Edit',
                                style: TextStyle(color: !isPaid ? AppColors.textPrimary : AppColors.textSecondary),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'pay',
                              enabled: !isPaid,
                              child: Text(
                                'Mark as Paid',
                                style: TextStyle(color: !isPaid ? AppColors.textPrimary : AppColors.textSecondary),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Method: $durationText', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rate: ₹${salary.dailyWage.toStringAsFixed(0)}/day',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      '₹${salary.totalSalary.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
  }

  Widget _buildDesktopTable(BuildContext context, List<_ResolvedSalaryItem> list) {
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
                      DataColumn(label: Text('Method & Duration')),
                      DataColumn(label: Text('Daily Wage')),
                      DataColumn(label: Text('Total Salary')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((item) {
                      final salary = item.salary;
                      final worker = item.worker;
                      final isPaid = salary.paymentStatus == 'paid';
                      final statusColor = isPaid ? AppColors.success : AppColors.warning;
                      final statusBgColor = statusColor.withValues(alpha: 0.1);

                      String durationText = '';
                      if (salary.calculationMethod == 'attendance') {
                        durationText = 'Automatic (${salary.presentDays} Days)';
                      } else {
                        durationText = 'Manual (${salary.durationValue} ${salary.durationUnit})';
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text(
                            worker.name ?? 'Unknown Worker',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(worker.gender.label)),
                          DataCell(Text(durationText)),
                          DataCell(Text('₹${salary.dailyWage.toStringAsFixed(2)}')),
                          DataCell(Text(
                            '₹${salary.totalSalary.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                salary.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) => _handleMenuSelection(val, salary),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'view', child: Text('View Details')),
                                PopupMenuItem(
                                  value: 'edit',
                                  enabled: !isPaid,
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(color: !isPaid ? AppColors.textPrimary : AppColors.textSecondary),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'pay',
                                  enabled: !isPaid,
                                  child: Text(
                                    'Mark as Paid',
                                    style: TextStyle(color: !isPaid ? AppColors.textPrimary : AppColors.textSecondary),
                                  ),
                                ),
                                const PopupMenuItem(
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

class _ResolvedSalaryItem {
  final SalaryModel salary;
  final WorkerModel worker;

  _ResolvedSalaryItem({
    required this.salary,
    required this.worker,
  });
}
