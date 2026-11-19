import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../models/farm_fertilizer_usage_model.dart';
import '../providers/farm_fertilizer_provider.dart';

class FarmFertilizerUsageDashboardScreen extends ConsumerStatefulWidget {
  const FarmFertilizerUsageDashboardScreen({super.key});

  @override
  ConsumerState<FarmFertilizerUsageDashboardScreen> createState() => _FarmFertilizerUsageDashboardScreenState();
}

class _FarmFertilizerUsageDashboardScreenState extends ConsumerState<FarmFertilizerUsageDashboardScreen> {
  String _chemicalQuery = '';
  DateTime? _chemStartDate;
  DateTime? _chemEndDate;

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

  void _confirmDeleteChemicalUsage(FarmFertilizerUsageModel record) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Usage Log',
        content: 'Are you sure you want to delete this chemical usage log? This will restore bags to stock.',
        confirmLabel: 'Delete',
        onConfirm: () async {
          await ref.read(farmChemicalUsagesProvider.notifier).deleteUsage(record.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usage log deleted successfully'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _selectDateRange() async {
    final initial = _chemStartDate != null ? DateTimeRange(start: _chemStartDate!, end: _chemEndDate ?? DateTime.now()) : null;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _chemStartDate = picked.start;
        _chemEndDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _chemStartDate = null;
      _chemEndDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = context.isDesktop || context.isTablet;
    final asyncUsages = ref.watch(farmChemicalUsagesProvider);
    final asyncInventory = ref.watch(farmChemicalInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chemical Usage Logs'),
        centerTitle: true,
      ),
      floatingActionButton: isDesktopOrTablet
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/farm/fertilizer/usage/add'),
              icon: const Icon(Icons.add),
              label: const Text('Log Chemical Usage'),
            ),
      body: SafeArea(
        child: asyncUsages.when(
          loading: () => const LoadingIndicator(message: 'Loading usages...'),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (usages) {
            final fertilizers = asyncInventory.value ?? [];
            final Map<String, String> fertNames = {for (var f in fertilizers) f.id: f.name};

            final filtered = usages.where((item) {
              final name = fertNames[item.fertilizerId]?.toLowerCase() ?? '';
              final notes = item.notes?.toLowerCase() ?? '';
              final q = _chemicalQuery.toLowerCase();
              if (_chemicalQuery.isNotEmpty && !name.contains(q) && !notes.contains(q)) {
                return false;
              }
              if (_chemStartDate != null) {
                try {
                  final d = DateTime.parse(item.date);
                  final start = DateTime(_chemStartDate!.year, _chemStartDate!.month, _chemStartDate!.day);
                  final end = _chemEndDate != null
                      ? DateTime(_chemEndDate!.year, _chemEndDate!.month, _chemEndDate!.day, 23, 59, 59)
                      : DateTime.now();
                  if (d.isBefore(start) || d.isAfter(end)) return false;
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
                          hintText: 'Search usages by name/notes...',
                          onChanged: (val) => setState(() => _chemicalQuery = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: Badge(isLabelVisible: _chemStartDate != null, child: const Icon(Icons.calendar_today)),
                        label: Text(_chemStartDate == null ? 'Filter Date' : 'Filtered'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (isDesktopOrTablet) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/farm/fertilizer/usage/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Log Chemical Usage'),
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
                if (_chemStartDate != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Date Filter'),
                        onPressed: _clearDateFilter,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: usages.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_outlined,
                          title: 'No Usages Logged',
                          description: 'Use the log usage button to record Chemical fertilizer usage.',
                        )
                      : filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No Matches Found',
                              description: 'Try adjusting your search query or date filters.',
                            )
                          : isDesktopOrTablet
                              ? _buildChemicalUsageTable(context, filtered, fertNames)
                              : _buildChemicalUsageList(context, filtered, fertNames),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChemicalUsageList(BuildContext context, List<FarmFertilizerUsageModel> list, Map<String, String> fertNames) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final fertName = fertNames[item.fertilizerId] ?? 'Unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.push('/farm/fertilizer/usage/detail/${item.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fertName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'view') {
                            context.push('/farm/fertilizer/usage/detail/${item.id}');
                          } else if (val == 'edit') {
                            context.push('/farm/fertilizer/usage/edit/${item.id}');
                          } else if (val == 'delete') {
                            _confirmDeleteChemicalUsage(item);
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
                      Text('Used: ${_formatBags(item.bagsUsed)} Bags', style: const TextStyle(color: AppColors.textSecondary)),
                      Text(
                        _formatPrettyDate(item.date),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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

  Widget _buildChemicalUsageTable(BuildContext context, List<FarmFertilizerUsageModel> list, Map<String, String> fertNames) {
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
                    DataColumn(label: Text('Chemical Fertilizer')),
                    DataColumn(label: Text('Bags Used')),
                    DataColumn(label: Text('Notes')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list.map((item) {
                    final fertName = fertNames[item.fertilizerId] ?? 'Unknown';
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatPrettyDate(item.date))),
                        DataCell(Text(fertName)),
                        DataCell(Text(_formatBags(item.bagsUsed), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(item.notes ?? '-')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                tooltip: 'View',
                                onPressed: () => context.push('/farm/fertilizer/usage/detail/${item.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => context.push('/farm/fertilizer/usage/edit/${item.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteChemicalUsage(item),
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
