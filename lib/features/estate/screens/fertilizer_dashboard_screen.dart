import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/organic_fertilizer_model.dart';
import '../providers/fertilizer_provider.dart';
import '../providers/organic_fertilizer_provider.dart';

class FertilizerDashboardScreen extends ConsumerStatefulWidget {
  const FertilizerDashboardScreen({super.key});

  @override
  ConsumerState<FertilizerDashboardScreen> createState() => _FertilizerDashboardScreenState();
}

class _FertilizerDashboardScreenState extends ConsumerState<FertilizerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search state
  String _inventorySearchQuery = '';
  String _usageSearchQuery = '';
  String _organicSearchQuery = '';

  // Filter state (Chemical)
  DateTime? _invStartDate;
  DateTime? _invEndDate;
  String? _invNameFilter;

  DateTime? _usageStartDate;
  DateTime? _usageEndDate;
  String? _usageNameFilter;

  // Filter state (Organic)
  DateTime? _organicStartDate;
  DateTime? _organicEndDate;
  String? _organicUnitFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  String _formatBags(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  String _formatLoads(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  void _confirmDeleteInventory(FertilizerModel fert) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Fertilizer',
        content: 'Are you sure you want to delete this fertilizer record? This will also remove any related usage logs.',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(fertilizerInventoryProvider.notifier).deleteFertilizer(fert.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fertilizer record deleted successfully'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteUsage(FertilizerUsageModel usage) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Usage Log',
        content: 'Are you sure you want to delete this stock usage log?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(fertilizerUsagesProvider.notifier).deleteUsage(usage.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usage log deleted successfully'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteOrganic(OrganicFertilizerModel organic) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Organic Purchase',
        content: 'Are you sure you want to delete this organic fertilizer record?',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(organicFertilizerListProvider.notifier).deleteOrganicFertilizer(organic.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Organic Fertilizer record deleted successfully'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, bool isInventory) {
    DateTime? tempStart = isInventory ? _invStartDate : _usageStartDate;
    DateTime? tempEnd = isInventory ? _invEndDate : _usageEndDate;
    String? tempName = isInventory ? _invNameFilter : _usageNameFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            Future<void> selectDate(bool isStartDate) async {
              final initial = isStartDate ? (tempStart ?? DateTime.now()) : (tempEnd ?? DateTime.now());
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setBottomSheetState(() {
                  if (isStartDate) {
                    tempStart = picked;
                    if (tempEnd != null && tempStart!.isAfter(tempEnd!)) tempEnd = tempStart;
                  } else {
                    tempEnd = picked;
                    if (tempStart != null && tempEnd!.isBefore(tempStart!)) tempStart = tempEnd;
                  }
                });
              }
            }

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
                          isInventory ? 'Filter Inventory' : 'Filter Usage',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => selectDate(true),
                            child: Text(tempStart == null ? 'Start Date' : tempStart!.toString().split(' ')[0]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => selectDate(false),
                            child: Text(tempEnd == null ? 'End Date' : tempEnd!.toString().split(' ')[0]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Fertilizer Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: tempName,
                      decoration: const InputDecoration(hintText: 'e.g. Urea', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      onChanged: (val) => tempName = val.trim().isEmpty ? null : val.trim(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                if (isInventory) {
                                  _invStartDate = null;
                                  _invEndDate = null;
                                  _invNameFilter = null;
                                } else {
                                  _usageStartDate = null;
                                  _usageEndDate = null;
                                  _usageNameFilter = null;
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isInventory) {
                                  _invStartDate = tempStart;
                                  _invEndDate = tempEnd;
                                  _invNameFilter = tempName;
                                } else {
                                  _usageStartDate = tempStart;
                                  _usageEndDate = tempEnd;
                                  _usageNameFilter = tempName;
                                }
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

  void _showOrganicFilterBottomSheet(BuildContext context) {
    DateTime? tempStart = _organicStartDate;
    DateTime? tempEnd = _organicEndDate;
    String? tempUnit = _organicUnitFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            Future<void> selectDate(bool isStartDate) async {
              final initial = isStartDate ? (tempStart ?? DateTime.now()) : (tempEnd ?? DateTime.now());
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setBottomSheetState(() {
                  if (isStartDate) {
                    tempStart = picked;
                    if (tempEnd != null && tempStart!.isAfter(tempEnd!)) tempEnd = tempStart;
                  } else {
                    tempEnd = picked;
                    if (tempStart != null && tempEnd!.isBefore(tempStart!)) tempStart = tempEnd;
                  }
                });
              }
            }

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
                          'Filter Organic Purchases',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => selectDate(true),
                            child: Text(tempStart == null ? 'Start Date' : tempStart!.toString().split(' ')[0]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => selectDate(false),
                            child: Text(tempEnd == null ? 'End Date' : tempEnd!.toString().split(' ')[0]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Unit Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: tempUnit,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      hint: const Text('All Units'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Units')),
                        DropdownMenuItem(value: 'Tractor', child: Text('Tractor')),
                        DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                        DropdownMenuItem(value: '407', child: Text('407')),
                        DropdownMenuItem(value: 'Lorry', child: Text('Lorry')),
                      ],
                      onChanged: (val) => tempUnit = val,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _organicStartDate = null;
                                _organicEndDate = null;
                                _organicUnitFilter = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _organicStartDate = tempStart;
                                _organicEndDate = tempEnd;
                                _organicUnitFilter = tempUnit;
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
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizer Management'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.warehouse_outlined), text: 'Inventory'),
            Tab(icon: Icon(Icons.remove_shopping_cart_outlined), text: 'Stock Usage'),
            Tab(icon: Icon(Icons.grass_outlined), text: 'Organic Fertilizer'),
          ],
        ),
      ),
      floatingActionButton: isDesktopOrTablet
          ? null
          : AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final index = _tabController.index;
                if (index == 0) {
                  return FloatingActionButton.extended(
                    onPressed: () => context.push('/estate/fertilizer/inventory/add?tab=chemical'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Fertilizer'),
                  );
                } else if (index == 1) {
                  return FloatingActionButton.extended(
                    onPressed: () => context.push('/estate/fertilizer/usage/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Log Usage'),
                  );
                } else {
                  return FloatingActionButton.extended(
                    onPressed: () => context.push('/estate/fertilizer/inventory/add?tab=organic'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Organic'),
                  );
                }
              },
            ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInventoryTab(context, isDesktopOrTablet),
            _buildUsageTab(context, isDesktopOrTablet),
            _buildOrganicTab(context, isDesktopOrTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab(BuildContext context, bool isDesktop) {
    final inventoryAsync = ref.watch(fertilizerInventoryProvider);
    final stockAsync = ref.watch(fertilizerStockMapProvider);
    final hasActiveFilters = _invStartDate != null || _invEndDate != null || _invNameFilter != null;

    return inventoryAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading inventory...'),
      error: (err, stack) => Center(child: Text('Error loading inventory: $err')),
      data: (list) {
        final filteredList = list.where((fert) {
          if (_inventorySearchQuery.isNotEmpty) {
            if (!fert.name.toLowerCase().contains(_inventorySearchQuery.toLowerCase())) return false;
          }
          if (_invNameFilter != null) {
            if (!fert.name.toLowerCase().contains(_invNameFilter!.toLowerCase())) return false;
          }
          if (_invStartDate != null) {
            try {
              final d = DateTime.parse(fert.date);
              if (d.isBefore(_invStartDate!)) return false;
            } catch (_) {}
          }
          if (_invEndDate != null) {
            try {
              final d = DateTime.parse(fert.date);
              if (d.isAfter(_invEndDate!)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search inventory by name...',
                      onChanged: (val) => setState(() => _inventorySearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showFilterBottomSheet(context, true),
                    icon: Badge(isLabelVisible: hasActiveFilters, child: const Icon(Icons.tune)),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/estate/fertilizer/inventory/add?tab=chemical'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Fertilizer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.warehouse_outlined,
                      title: 'No Fertilizers Added',
                      description: 'No fertilizers added yet.',
                    )
                  : filteredList.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No Matches Found',
                          description: 'Try adjusting your search query or active filters.',
                        )
                      : isDesktop
                          ? _buildInventoryTable(context, filteredList, stockAsync.value ?? {})
                          : _buildInventoryList(context, filteredList, stockAsync.value ?? {}),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInventoryList(BuildContext context, List<FertilizerModel> list, Map<String, double> stockMap) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final fert = list[index];
        final currentStock = stockMap[fert.id] ?? 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/estate/fertilizer/inventory/detail/${fert.id}'),
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
                        fert.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'view') {
                            context.push('/estate/fertilizer/inventory/detail/${fert.id}');
                          } else if (val == 'edit') {
                            context.push('/estate/fertilizer/inventory/edit/${fert.id}');
                          } else if (val == 'delete') {
                            _confirmDeleteInventory(fert);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'view', child: Text('View Details')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stock: ${_formatBags(currentStock)} Bags (${fert.quantityPerBag} ${fert.unit}/Bag)', style: const TextStyle(color: AppColors.textSecondary)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Price: ₹${fert.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            '₹${fert.totalPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Purchased on ${_formatPrettyDate(fert.date)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventoryTable(BuildContext context, List<FertilizerModel> list, Map<String, double> stockMap) {
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
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Fertilizer Name')),
                      DataColumn(label: Text('Stock (Bags)')),
                      DataColumn(label: Text('Quantity Per Bag')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Total Price')),
                      DataColumn(label: Text('Purchase Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((fert) {
                      final currentStock = stockMap[fert.id] ?? 0.0;
                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/fertilizer/inventory/detail/${fert.id}'),
                        cells: [
                          DataCell(Text(fert.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('${_formatBags(currentStock)} Bags')),
                          DataCell(Text('${fert.quantityPerBag} ${fert.unit}')),
                          DataCell(Text('₹${fert.price.toStringAsFixed(2)}')),
                          DataCell(Text('₹${fert.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataCell(Text(_formatPrettyDate(fert.date))),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) {
                                if (val == 'view') {
                                  context.push('/estate/fertilizer/inventory/detail/${fert.id}');
                                } else if (val == 'edit') {
                                  context.push('/estate/fertilizer/inventory/edit/${fert.id}');
                                } else if (val == 'delete') {
                                  _confirmDeleteInventory(fert);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'view', child: Text('View Details')),
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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

  Widget _buildUsageTab(BuildContext context, bool isDesktop) {
    final usagesAsync = ref.watch(fertilizerUsagesProvider);
    final inventoryAsync = ref.watch(fertilizerInventoryProvider);
    final hasActiveFilters = _usageStartDate != null || _usageEndDate != null || _usageNameFilter != null;

    return usagesAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading usage logs...'),
      error: (err, stack) => Center(child: Text('Error loading usage logs: $err')),
      data: (usageList) {
        return inventoryAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading stock references...'),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (inventoryList) {
            final filteredList = usageList.where((usage) {
              final fert = inventoryList.where((f) => f.id == usage.fertilizerId).firstOrNull;
              final fertName = fert?.name ?? 'Deleted Fertilizer';

              if (_usageSearchQuery.isNotEmpty) {
                if (!fertName.toLowerCase().contains(_usageSearchQuery.toLowerCase())) return false;
              }
              if (_usageNameFilter != null) {
                if (!fertName.toLowerCase().contains(_usageNameFilter!.toLowerCase())) return false;
              }
              if (_usageStartDate != null) {
                try {
                  final d = DateTime.parse(usage.date);
                  if (d.isBefore(_usageStartDate!)) return false;
                } catch (_) {}
              }
              if (_usageEndDate != null) {
                try {
                  final d = DateTime.parse(usage.date);
                  if (d.isAfter(_usageEndDate!)) return false;
                } catch (_) {}
              }
              return true;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          hintText: 'Search usage by fertilizer name...',
                          onChanged: (val) => setState(() => _usageSearchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showFilterBottomSheet(context, false),
                        icon: Badge(isLabelVisible: hasActiveFilters, child: const Icon(Icons.tune)),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/estate/fertilizer/usage/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Log Usage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: usageList.isEmpty
                      ? const EmptyState(
                          icon: Icons.remove_shopping_cart_outlined,
                          title: 'No Usage Logs',
                          description: 'No fertilizer usage records.',
                        )
                      : filteredList.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches Found',
                              description: 'Try adjusting your search query or active filters.',
                            )
                          : isDesktop
                              ? _buildUsageTable(context, filteredList, inventoryList)
                              : _buildUsageList(context, filteredList, inventoryList),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUsageList(BuildContext context, List<FertilizerUsageModel> list, List<FertilizerModel> inventoryList) {
    final theme = Theme.of(context);
    final stockMap = ref.watch(fertilizerStockMapProvider).value ?? {};

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final usage = list[index];
        final fert = inventoryList.where((f) => f.id == usage.fertilizerId).firstOrNull;
        final fertName = fert?.name ?? 'Deleted Fertilizer';
        final remainingStock = stockMap[usage.fertilizerId] ?? 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/estate/fertilizer/usage/detail/${usage.id}'),
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
                        _formatPrettyDate(usage.date),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'view') {
                            context.push('/estate/fertilizer/usage/detail/${usage.id}');
                          } else if (val == 'edit') {
                            context.push('/estate/fertilizer/usage/edit/${usage.id}');
                          } else if (val == 'delete') {
                            _confirmDeleteUsage(usage);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'view', child: Text('View Details')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fertName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bags Used: ${_formatBags(usage.bagsUsed)} Bags', style: const TextStyle(color: AppColors.textSecondary)),
                      Text('Remaining: ${_formatBags(remainingStock)} Bags', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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

  Widget _buildUsageTable(BuildContext context, List<FertilizerUsageModel> list, List<FertilizerModel> inventoryList) {
    final stockMap = ref.watch(fertilizerStockMapProvider).value ?? {};

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
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Fertilizer Name')),
                      DataColumn(label: Text('Bags Used')),
                      DataColumn(label: Text('Remaining Stock')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((usage) {
                      final fert = inventoryList.where((f) => f.id == usage.fertilizerId).firstOrNull;
                      final fertName = fert?.name ?? 'Deleted Fertilizer';
                      final remainingStock = stockMap[usage.fertilizerId] ?? 0.0;

                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/fertilizer/usage/detail/${usage.id}'),
                        cells: [
                          DataCell(Text(_formatPrettyDate(usage.date), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(fertName)),
                          DataCell(Text('${_formatBags(usage.bagsUsed)} Bags', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
                          DataCell(Text('${_formatBags(remainingStock)} Bags')),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) {
                                if (val == 'view') {
                                  context.push('/estate/fertilizer/usage/detail/${usage.id}');
                                } else if (val == 'edit') {
                                  context.push('/estate/fertilizer/usage/edit/${usage.id}');
                                } else if (val == 'delete') {
                                  _confirmDeleteUsage(usage);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'view', child: Text('View Details')),
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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

  Widget _buildOrganicTab(BuildContext context, bool isDesktop) {
    final organicAsync = ref.watch(organicFertilizerListProvider);
    final hasActiveFilters = _organicStartDate != null || _organicEndDate != null || _organicUnitFilter != null;

    return organicAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading organic inventory...'),
      error: (err, stack) => Center(child: Text('Error loading organic inventory: $err')),
      data: (list) {
        final filteredList = list.where((item) {
          if (_organicSearchQuery.isNotEmpty) {
            if (!item.name.toLowerCase().contains(_organicSearchQuery.toLowerCase())) return false;
          }
          if (_organicUnitFilter != null) {
            if (item.unit != _organicUnitFilter) return false;
          }
          if (_organicStartDate != null) {
            try {
              final d = DateTime.parse(item.date);
              if (d.isBefore(_organicStartDate!)) return false;
            } catch (_) {}
          }
          if (_organicEndDate != null) {
            try {
              final d = DateTime.parse(item.date);
              if (d.isAfter(_organicEndDate!)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search organic by name...',
                      onChanged: (val) => setState(() => _organicSearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showOrganicFilterBottomSheet(context),
                    icon: Badge(isLabelVisible: hasActiveFilters, child: const Icon(Icons.tune)),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/estate/fertilizer/inventory/add?tab=organic'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Organic'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.grass_outlined,
                      title: 'No Organic Fertilizer Added',
                      description: 'No organic fertilizer purchase records added yet.',
                    )
                  : filteredList.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No Matches Found',
                          description: 'Try adjusting your search query or active filters.',
                        )
                      : isDesktop
                          ? _buildOrganicTable(context, filteredList)
                          : _buildOrganicList(context, filteredList),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrganicList(BuildContext context, List<OrganicFertilizerModel> list) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/estate/fertilizer/organic/detail/${item.id}'),
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
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'view') {
                            context.push('/estate/fertilizer/organic/detail/${item.id}');
                          } else if (val == 'edit') {
                            context.push('/estate/fertilizer/organic/edit/${item.id}');
                          } else if (val == 'delete') {
                            _confirmDeleteOrganic(item);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'view', child: Text('View Details')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Loads: ${_formatLoads(item.loads)} (${item.unit})', style: const TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Purchased on ${_formatPrettyDate(item.date)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganicTable(BuildContext context, List<OrganicFertilizerModel> list) {
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
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Organic Fertilizer Name')),
                      DataColumn(label: Text('Loads')),
                      DataColumn(label: Text('Unit')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((item) {
                      return DataRow(
                        onSelectChanged: (_) => context.push('/estate/fertilizer/organic/detail/${item.id}'),
                        cells: [
                          DataCell(Text(_formatPrettyDate(item.date))),
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(_formatLoads(item.loads))),
                          DataCell(Text(item.unit)),
                          DataCell(Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) {
                                if (val == 'view') {
                                  context.push('/estate/fertilizer/organic/detail/${item.id}');
                                } else if (val == 'edit') {
                                  context.push('/estate/fertilizer/organic/edit/${item.id}');
                                } else if (val == 'delete') {
                                  _confirmDeleteOrganic(item);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'view', child: Text('View Details')),
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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
