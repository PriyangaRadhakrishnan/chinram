import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/fertilizer_usage_model.dart';
import '../providers/fertilizer_provider.dart';

class FertilizerUsageFormScreen extends ConsumerStatefulWidget {
  final String? usageId;

  const FertilizerUsageFormScreen({
    super.key,
    this.usageId,
  });

  @override
  ConsumerState<FertilizerUsageFormScreen> createState() => _FertilizerUsageFormScreenState();
}

class _FertilizerUsageFormScreenState extends ConsumerState<FertilizerUsageFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedFertilizerId;
  final _bagsUsedController = TextEditingController();

  bool _initialized = false;
  FertilizerUsageModel? _editingUsage;

  @override
  void initState() {
    super.initState();
    _bagsUsedController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bagsUsedController.dispose();
    super.dispose();
  }

  String _formatBags(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  String _formatDateString(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _getCurrentTimeString() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save(double maxAllowedBags) async {
    if (_formKey.currentState!.validate()) {
      final isEdit = _editingUsage != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingUsage!.createdDate : nowStr;
      final String createdT = isEdit ? _editingUsage!.createdTime : timeStr;

      final usedVal = double.tryParse(_bagsUsedController.text) ?? 0.0;

      if (usedVal > maxAllowedBags) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient fertilizer stock.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final usage = FertilizerUsageModel(
        id: isEdit ? _editingUsage!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        date: _formatDateString(_selectedDate),
        fertilizerId: _selectedFertilizerId!,
        bagsUsed: usedVal,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(fertilizerUsagesProvider.notifier).updateUsage(usage);
      } else {
        await ref.read(fertilizerUsagesProvider.notifier).addUsage(usage);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Usage updated successfully' : 'Usage logged successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(fertilizerInventoryProvider);
    final usagesAsync = ref.watch(fertilizerUsagesProvider);
    final stockAsync = ref.watch(fertilizerStockMapProvider);
    final theme = Theme.of(context);

    // Populate edit data
    if (widget.usageId != null && !_initialized && usagesAsync.hasValue) {
      final list = usagesAsync.value ?? [];
      final editUsage = list.where((u) => u.id == widget.usageId).firstOrNull;
      if (editUsage != null) {
        _editingUsage = editUsage;
        _selectedDate = DateTime.tryParse(editUsage.date) ?? _selectedDate;
        _selectedFertilizerId = editUsage.fertilizerId;
        _bagsUsedController.text = _formatBags(editUsage.bagsUsed);
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usageId == null ? 'Log Usage' : 'Edit Usage'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: inventoryAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading inventory...'),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (inventoryList) {
            if (inventoryList.isEmpty) {
              return const EmptyState(
                icon: Icons.grass,
                title: 'No Fertilizer Inventory',
                description: 'Please add fertilizer to the inventory before logging stock usage.',
              );
            }

            // Exclude empty batches unless editing
            final stockMap = stockAsync.value ?? {};
            final activeInventory = inventoryList.where((f) {
              final stock = stockMap[f.id] ?? 0.0;
              if (stock > 0) return true;
              if (widget.usageId != null && f.id == _selectedFertilizerId) return true;
              return false;
            }).toList();

            if (activeInventory.isEmpty) {
              return const EmptyState(
                icon: Icons.report_problem_outlined,
                title: 'No Available Stock',
                description: 'All inventory items currently have 0 bags in stock.',
              );
            }

            _selectedFertilizerId ??= activeInventory.first.id;

            final selectedFert = activeInventory.firstWhere(
              (f) => f.id == _selectedFertilizerId,
              orElse: () => activeInventory.first,
            );

            // Calculate current stock for the selected fertilizer
            final rawStock = stockMap[selectedFert.id] ?? 0.0;
            // Add back the edited bags if we are editing this batch
            final isEdit = _editingUsage != null && _editingUsage!.fertilizerId == selectedFert.id;
            final currentStock = rawStock + (isEdit ? _editingUsage!.bagsUsed : 0.0);

            final bagsUsed = double.tryParse(_bagsUsedController.text) ?? 0.0;
            final remainingStock = currentStock - bagsUsed;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Stock Usage',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 24),

                    // Date
                    const Text('Date *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_formatDateString(_selectedDate)),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown
                    const Text('Fertilizer Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedFertilizerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: activeInventory.map((f) {
                        final batchStock = stockMap[f.id] ?? 0.0;
                        final displayStock = batchStock + ((_editingUsage != null && _editingUsage!.fertilizerId == f.id) ? _editingUsage!.bagsUsed : 0.0);
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text('${f.name} (Batch: ${f.date}, Stock: ${_formatBags(displayStock)} Bags)'),
                        );
                      }).toList(),
                      onChanged: widget.usageId != null
                          ? null // Lock dropdown on edit mode
                          : (val) {
                              setState(() {
                                _selectedFertilizerId = val;
                                _bagsUsedController.clear();
                              });
                            },
                    ),
                    const SizedBox(height: 20),

                    // Current Stock (read-only)
                    const Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      key: ValueKey('currentStock_$currentStock'),
                      initialValue: '${_formatBags(currentStock)} Bags',
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.disabledColor.withValues(alpha: 0.05),
                        prefixIcon: const Icon(Icons.inventory_2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bags Used
                    const Text('Bags Used *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _bagsUsedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 5.5',
                        prefixIcon: Icon(Icons.remove_circle_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter bags count';
                        final parsed = double.tryParse(val);
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed <= 0) return 'Must be > 0';
                        if (parsed > currentStock) {
                          return 'Insufficient fertilizer stock.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Remaining Stock Summary
                    Card(
                      color: remainingStock < 0
                          ? AppColors.error.withValues(alpha: 0.05)
                          : AppColors.primary.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Remaining Stock (Bags)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${_formatBags(remainingStock)} Bags',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: remainingStock < 0 ? AppColors.error : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _save(currentStock),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(widget.usageId == null ? 'Log Usage' : 'Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
