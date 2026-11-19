import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/farm_fertilizer_model.dart';
import '../models/farm_organic_fertilizer_model.dart';
import '../providers/farm_fertilizer_provider.dart';

class FarmFertilizerDashboardScreen extends ConsumerStatefulWidget {
  const FarmFertilizerDashboardScreen({super.key});

  @override
  ConsumerState<FarmFertilizerDashboardScreen> createState() => _FarmFertilizerDashboardScreenState();
}

class _FarmFertilizerDashboardScreenState extends ConsumerState<FarmFertilizerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _chemicalSearchQuery = '';
  String _organicSearchQuery = '';

  // Chemical filter states
  DateTime? _chemStartDate;
  DateTime? _chemEndDate;
  String? _chemNameFilter;

  // Organic filter states
  DateTime? _orgStartDate;
  DateTime? _orgEndDate;
  String? _orgUnitFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void _confirmDeleteChemical(FarmFertilizerModel record) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Fertilizer',
        content: 'Are you sure you want to delete this chemical fertilizer record? This will also remove any related usage logs.',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(farmChemicalInventoryProvider.notifier).deleteChemical(record.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fertilizer record deleted successfully'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteOrganic(FarmOrganicFertilizerModel record) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Organic Purchase',
        content: 'Are you sure you want to delete this organic fertilizer record? This will also remove any related usage logs.',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(farmOrganicInventoryProvider.notifier).deleteOrganic(record.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Organic Fertilizer record deleted successfully'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _showChemicalFilterBottomSheet(BuildContext context) {
    DateTime? tempStart = _chemStartDate;
    DateTime? tempEnd = _chemEndDate;
    String? tempName = _chemNameFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            void selectDate(bool isStartDate) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isStartDate ? (tempStart ?? DateTime.now()) : (tempEnd ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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
                          'Filter Chemical Purchases',
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
                      decoration: const InputDecoration(
                        hintText: 'e.g. Urea, Potash',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (val) => tempName = val.trim(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _chemStartDate = null;
                                _chemEndDate = null;
                                _chemNameFilter = null;
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
                                _chemStartDate = tempStart;
                                _chemEndDate = tempEnd;
                                _chemNameFilter = tempName;
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
    DateTime? tempStart = _orgStartDate;
    DateTime? tempEnd = _orgEndDate;
    String? tempUnit = _orgUnitFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            void selectDate(bool isStartDate) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isStartDate ? (tempStart ?? DateTime.now()) : (tempEnd ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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
                    const Text('Vehicle Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: tempUnit,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      hint: const Text('All Vehicles'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Vehicles')),
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
                                _orgStartDate = null;
                                _orgEndDate = null;
                                _orgUnitFilter = null;
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
                                _orgStartDate = tempStart;
                                _orgEndDate = tempEnd;
                                _orgUnitFilter = tempUnit;
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
        title: const Text('Farm Fertilizer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'View Stock Usages',
            onPressed: () => context.push('/farm/fertilizer/usage'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.warehouse_outlined), text: 'Chemical'),
            Tab(icon: Icon(Icons.grass_outlined), text: 'Organic'),
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
                    onPressed: () => context.push('/farm/fertilizer/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Chemical'),
                  );
                } else {
                  return FloatingActionButton.extended(
                    onPressed: () => context.push('/farm/fertilizer/organic/add'),
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
            _buildChemicalInventoryTab(),
            _buildOrganicInventoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalInventoryTab() {
    final asyncList = ref.watch(farmChemicalInventoryProvider);
    final stockMap = ref.watch(farmChemicalStockMapProvider);
    final isDesktop = context.isDesktop;

    return asyncList.when(
      loading: () => const LoadingIndicator(message: 'Loading inventory...'),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (list) {
        // Apply Filters
        final filteredList = list.where((item) {
          if (_chemicalSearchQuery.isNotEmpty && !item.name.toLowerCase().contains(_chemicalSearchQuery.toLowerCase())) {
            return false;
          }
          if (_chemNameFilter != null && !item.name.toLowerCase().contains(_chemNameFilter!.toLowerCase())) {
            return false;
          }
          if (_chemStartDate != null) {
            try {
              final d = DateTime.parse(item.date);
              if (d.isBefore(_chemStartDate!) || (d.isAtSameMomentAs(_chemStartDate!))) {
                // inclusive bounds checked below
              }
              final start = DateTime(_chemStartDate!.year, _chemStartDate!.month, _chemStartDate!.day);
              final end = _chemEndDate != null ? DateTime(_chemEndDate!.year, _chemEndDate!.month, _chemEndDate!.day, 23, 59, 59) : DateTime.now();
              if (d.isBefore(start) || d.isAfter(end)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();

        final hasActiveFilters = _chemStartDate != null || _chemNameFilter != null;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search chemical by name...',
                      onChanged: (val) => setState(() => _chemicalSearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showChemicalFilterBottomSheet(context),
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
                      onPressed: () => context.push('/farm/fertilizer/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Chemical'),
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
                      title: 'No chemical fertilizers logged',
                      description: 'Use the add button to log purchase batches.',
                    )
                  : filteredList.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No Matches Found',
                          description: 'Try adjusting your filters or search keywords.',
                        )
                      : isDesktop
                          ? _buildChemicalTable(context, filteredList, stockMap)
                          : _buildChemicalList(context, filteredList, stockMap),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChemicalList(BuildContext context, List<FarmFertilizerModel> list, Map<String, double> stockMap) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final fert = list[index];
        final remaining = stockMap[fert.id] ?? 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/farm/fertilizer/detail/${fert.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fert.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'view') {
                            context.push('/farm/fertilizer/detail/${fert.id}');
                          } else if (val == 'edit') {
                            context.push('/farm/fertilizer/edit/${fert.id}');
                          } else if (val == 'delete') {
                            _confirmDeleteChemical(fert);
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
                      Text(
                        'Stock: ${_formatBags(remaining)} Bags (${fert.quantityPerBag} Kg/Bag)',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        formatINR(fert.price),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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

  Widget _buildChemicalTable(BuildContext context, List<FarmFertilizerModel> list, Map<String, double> stockMap) {
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
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Bags Purchased')),
                    DataColumn(label: Text('Qty/Bag')),
                    DataColumn(label: Text('Remaining Bags')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list.map((fert) {
                    final remaining = stockMap[fert.id] ?? 0.0;
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatPrettyDate(fert.date))),
                        DataCell(Text(fert.name)),
                        DataCell(Text(_formatBags(fert.initialStock))),
                        DataCell(Text('${fert.quantityPerBag} Kg')),
                        DataCell(Text(_formatBags(remaining), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(formatINR(fert.price))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                tooltip: 'View',
                                onPressed: () => context.push('/farm/fertilizer/detail/${fert.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => context.push('/farm/fertilizer/edit/${fert.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteChemical(fert),
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

  Widget _buildOrganicInventoryTab() {
    final asyncList = ref.watch(farmOrganicInventoryProvider);
    final isDesktop = context.isDesktop;

    return asyncList.when(
      loading: () => const LoadingIndicator(message: 'Loading inventory...'),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (list) {
        // Apply Filters
        final filteredList = list.where((item) {
          if (_organicSearchQuery.isNotEmpty && !item.name.toLowerCase().contains(_organicSearchQuery.toLowerCase())) {
            return false;
          }
          if (_orgUnitFilter != null && item.unit != _orgUnitFilter) {
            return false;
          }
          if (_orgStartDate != null) {
            try {
              final d = DateTime.parse(item.date);
              final start = DateTime(_orgStartDate!.year, _orgStartDate!.month, _orgStartDate!.day);
              final end = _orgEndDate != null ? DateTime(_orgEndDate!.year, _orgEndDate!.month, _orgEndDate!.day, 23, 59, 59) : DateTime.now();
              if (d.isBefore(start) || d.isAfter(end)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();

        final hasActiveFilters = _orgStartDate != null || _orgUnitFilter != null;

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
                      onPressed: () => context.push('/farm/fertilizer/organic/add'),
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
                      title: 'No organic fertilizer logged',
                      description: 'Use the add button to log organic purchases.',
                    )
                  : filteredList.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No Matches Found',
                          description: 'Try adjusting your filters or search keywords.',
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

  Widget _buildOrganicList(BuildContext context, List<FarmOrganicFertilizerModel> list) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/farm/fertilizer/organic/detail/${record.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(record.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'view') {
                            context.push('/farm/fertilizer/organic/detail/${record.id}');
                          } else if (val == 'edit') {
                            context.push('/farm/fertilizer/organic/edit/${record.id}');
                          } else if (val == 'delete') {
                            _confirmDeleteOrganic(record);
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
                      Text(
                        'Purchased: ${_formatLoads(record.loads)} ${record.unit} loads',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        formatINR(record.price),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Purchased on ${_formatPrettyDate(record.date)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganicTable(BuildContext context, List<FarmOrganicFertilizerModel> list) {
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
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Organic Fertilizer')),
                    DataColumn(label: Text('Loads Purchased')),
                    DataColumn(label: Text('Vehicle Type')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list.map((record) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatPrettyDate(record.date))),
                        DataCell(Text(record.name)),
                        DataCell(Text(_formatLoads(record.loads))),
                        DataCell(Text(record.unit)),
                        DataCell(Text(formatINR(record.price))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                tooltip: 'View',
                                onPressed: () => context.push('/farm/fertilizer/organic/detail/${record.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => context.push('/farm/fertilizer/organic/edit/${record.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteOrganic(record),
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
