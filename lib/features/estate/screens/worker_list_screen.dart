import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/filter_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/worker_model.dart';
import '../providers/worker_provider.dart';

class WorkerListScreen extends ConsumerStatefulWidget {
  const WorkerListScreen({super.key});

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen> {
  String _searchQuery = '';
  FilterState _filters = const FilterState();

  void _confirmDelete(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Worker',
        content: 'Are you sure you want to delete this worker?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(workerListProvider.notifier).deleteWorker(worker.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Worker deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, WorkerModel worker) {
    switch (value) {
      case 'view':
        context.push('/estate/workers/detail/${worker.id}');
        break;
      case 'edit':
        context.push('/estate/workers/edit/${worker.id}');
        break;
      case 'delete':
        _confirmDelete(worker);
        break;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Retain current filter state locally
    WorkerGender? localGender = _filters.gender != null ? WorkerGender.fromString(_filters.gender) : null;
    WorkerStatus? localStatus = _filters.status != null ? WorkerStatus.fromString(_filters.status) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gender Dropdown
                  Text(
                    'Gender',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WorkerGender?>(
                    initialValue: localGender,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: WorkerGender.male, child: Text('Male')),
                      DropdownMenuItem(value: WorkerGender.female, child: Text('Female')),
                    ],
                    onChanged: (val) {
                      setBottomSheetState(() {
                        localGender = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Status Dropdown
                  Text(
                    'Status',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WorkerStatus?>(
                    initialValue: localStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: WorkerStatus.active, child: Text('Active')),
                      DropdownMenuItem(value: WorkerStatus.inactive, child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      setBottomSheetState(() {
                        localStatus = val;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bottom Sheet Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setBottomSheetState(() {
                              localGender = null;
                              localStatus = null;
                            });
                            setState(() {
                              _filters = const FilterState();
                            });
                            Navigator.of(context).pop();
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
                              _filters = FilterState(
                                gender: localGender?.label,
                                status: localStatus?.label,
                              );
                            });
                            Navigator.of(context).pop();
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
    final asyncList = ref.watch(workerListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final hasActiveFilters = _filters.gender != null || _filters.status != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        centerTitle: true,
        actions: isDesktopOrTablet
            ? [
                TextButton.icon(
                  onPressed: () => context.push('/estate/workers/add'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Worker',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
              ]
            : null,
      ),
      floatingActionButton: !isDesktopOrTablet
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/estate/workers/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Worker'),
            )
          : null,
      body: SafeArea(
        child: asyncList.when(
          loading: () => const LoadingIndicator(message: 'Loading workers...'),
          error: (err, stack) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Workers',
            description: err.toString(),
            actionLabel: 'Retry',
            onActionPressed: () => ref.refresh(workerListProvider),
          ),
          data: (list) {
            // Apply search & filter
            final filteredList = list.where((w) {
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final nameMatches = w.name?.toLowerCase().contains(query) ?? false;
                final phoneMatches = w.phoneNumber?.toLowerCase().contains(query) ?? false;
                if (!nameMatches && !phoneMatches) {
                  return false;
                }
              }

              if (_filters.gender != null) {
                if (w.gender.label.toLowerCase() != _filters.gender!.toLowerCase()) {
                  return false;
                }
              }

              if (_filters.status != null) {
                if (w.status.label.toLowerCase() != _filters.status!.toLowerCase()) {
                  return false;
                }
              }

              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          hintText: 'Search by name or phone...',
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
                  child: list.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Workers Yet',
                          description: 'No workers added yet.',
                        )
                      : filteredList.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches',
                              description: 'No workers match the selected search or filters.',
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

  Widget _buildMobileList(BuildContext context, List<WorkerModel> list) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final worker = list[index];
        final displayName = (worker.name == null || worker.name!.trim().isEmpty) ? '-' : worker.name!;
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
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        _StatusBadge(status: worker.status),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (val) => _handleMenuSelection(val, worker),
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
                Row(
                  children: [
                    const Icon(Icons.wc, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      worker.gender.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      worker.phoneNumber ?? '-',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _buildDesktopTable(BuildContext context, List<WorkerModel> list) {
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
                      DataColumn(label: Text('Phone Number')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((worker) {
                      final displayName = (worker.name == null || worker.name!.trim().isEmpty) ? '-' : worker.name!;
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          DataCell(Text(worker.gender.label)),
                          DataCell(Text(worker.phoneNumber ?? '-')),
                          DataCell(_StatusBadge(status: worker.status)),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) => _handleMenuSelection(val, worker),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WorkerStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = status == WorkerStatus.active;
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    final bgColor = isActive
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.textSecondary.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
