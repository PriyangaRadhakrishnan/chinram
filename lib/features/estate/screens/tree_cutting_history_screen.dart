import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/tree_cutting_model.dart';
import '../providers/tree_cutting_provider.dart';

class TreeCuttingHistoryScreen extends ConsumerStatefulWidget {
  const TreeCuttingHistoryScreen({super.key});

  @override
  ConsumerState<TreeCuttingHistoryScreen> createState() => _TreeCuttingHistoryScreenState();
}

class _TreeCuttingHistoryScreenState extends ConsumerState<TreeCuttingHistoryScreen> {
  String _searchQuery = '';

  // Filters
  String? _placeFilter;
  String? _treeNameFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmDelete(TreeCuttingModel record) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Record',
        content: 'Are you sure you want to delete this tree cutting record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(treeCuttingListProvider.notifier).deleteTreeCutting(record.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Record deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuSelection(String value, TreeCuttingModel record) {
    switch (value) {
      case 'view':
        context.push('/estate/maravettu/detail/${record.id}');
        break;
      case 'edit':
        context.push('/estate/maravettu/edit/${record.id}');
        break;
      case 'delete':
        _confirmDelete(record);
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
    String? tempPlace = _placeFilter;
    String? tempTreeName = _treeNameFilter;

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
                          'Filter Records',
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

                    // Date range
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

                    // Place Name
                    const Text('Place Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: tempPlace,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Area A',
                        prefixIcon: Icon(Icons.place),
                      ),
                      onChanged: (val) => tempPlace = val.trim().isEmpty ? null : val.trim(),
                    ),
                    const SizedBox(height: 16),

                    // Tree Name
                    const Text('Tree Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: tempTreeName,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Coffee',
                        prefixIcon: Icon(Icons.nature),
                      ),
                      onChanged: (val) => tempTreeName = val.trim().isEmpty ? null : val.trim(),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                                _placeFilter = null;
                                _treeNameFilter = null;
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                _placeFilter = tempPlace;
                                _treeNameFilter = tempTreeName;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final listAsync = ref.watch(treeCuttingListProvider);
    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final hasActiveFilters = _startDate != null || _endDate != null || _placeFilter != null || _treeNameFilter != null;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mara Vettu (Tree Cutting)'),
        centerTitle: true,
        actions: [
          if (isDesktopOrTablet)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/estate/maravettu/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add Tree Cutting'),
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
              onPressed: () => context.push('/estate/maravettu/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Tree Cutting'),
            ),
      body: SafeArea(
        child: listAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading cutting records...'),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (allRecords) {
            // Apply Search and Filters
            final filteredList = allRecords.where((record) {
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                if (!(record.treeName ?? '').toLowerCase().contains(query) &&
                    !(record.placeName ?? '').toLowerCase().contains(query)) {
                  return false;
                }
              }
 
              if (_placeFilter != null) {
                if (!(record.placeName ?? '').toLowerCase().contains(_placeFilter!.toLowerCase())) return false;
              }

              if (_treeNameFilter != null) {
                if (!(record.treeName ?? '').toLowerCase().contains(_treeNameFilter!.toLowerCase())) return false;
              }

              if (_startDate != null) {
                try {
                  final d = DateTime.parse(record.date);
                  if (d.isBefore(_startDate!)) return false;
                } catch (_) {}
              }
              if (_endDate != null) {
                try {
                  final d = DateTime.parse(record.date);
                  if (d.isAfter(_endDate!)) return false;
                } catch (_) {}
              }

              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (allRecords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBarWidget(
                            hintText: 'Search by tree or plot...',
                            onChanged: (val) => setState(() => _searchQuery = val),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: allRecords.isEmpty
                      ? const EmptyState(
                          icon: Icons.forest_outlined,
                          title: 'No Cutting Records',
                          description: 'No tree cutting records available.',
                        )
                      : filteredList.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches Found',
                              description: 'Adjust your search query or active filters.',
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

  Widget _buildMobileList(BuildContext context, List<TreeCuttingModel> list) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/estate/maravettu/detail/${record.id}'),
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
                        record.treeName ?? '-',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
                      Text('Place: ${record.placeName ?? '-'}', style: const TextStyle(color: AppColors.textSecondary)),
                      Text(
                        record.numberOfTrees != null ? '${record.numberOfTrees} Cut' : 'Cut: -',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrettyDate(record.date),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      Text(
                        '₹${record.totalAmount.toStringAsFixed(2)}',
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
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<TreeCuttingModel> list) {
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
                      DataColumn(label: Text('Record Date')),
                      DataColumn(label: Text('Tree Name')),
                      DataColumn(label: Text('Place Name')),
                      DataColumn(label: Text('Trees Cut')),
                      DataColumn(label: Text('Total Amount (₹)')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((record) {
                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/maravettu/detail/${record.id}'),
                        cells: [
                          DataCell(Text(_formatPrettyDate(record.date))),
                          DataCell(Text(
                            record.treeName ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(record.placeName ?? '-')),
                          DataCell(Text(
                            record.numberOfTrees != null ? '${record.numberOfTrees} Trees' : '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                          )),
                          DataCell(Text(
                            '₹${record.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          )),
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
}
