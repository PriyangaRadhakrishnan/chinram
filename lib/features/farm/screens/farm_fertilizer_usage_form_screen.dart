import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/farm_fertilizer_usage_model.dart';
import '../providers/farm_fertilizer_provider.dart';

class FarmFertilizerUsageFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const FarmFertilizerUsageFormScreen({super.key, this.id});

  @override
  ConsumerState<FarmFertilizerUsageFormScreen> createState() => _FarmFertilizerUsageFormScreenState();
}

class _FarmFertilizerUsageFormScreenState extends ConsumerState<FarmFertilizerUsageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _isLoading = false;

  final _dateController = TextEditingController();
  final _bagsUsedController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedFertilizerId;
  DateTime _selectedDate = DateTime.now();
  FarmFertilizerUsageModel? _existingRecord;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.id != null;
    _dateController.text = _selectedDate.toString().split(' ')[0];

    if (_isEdit) {
      _loadExisting();
    }
  }

  void _loadExisting() async {
    setState(() => _isLoading = true);
    final list = await ref.read(farmChemicalUsagesProvider.future);
    final match = list.where((item) => item.id == widget.id).firstOrNull;
    if (match != null) {
      _existingRecord = match;
      _selectedDate = DateTime.parse(match.date);
      _dateController.text = match.date;
      _selectedFertilizerId = match.fertilizerId;
      _bagsUsedController.text = match.bagsUsed % 1 == 0 ? match.bagsUsed.toInt().toString() : match.bagsUsed.toString();
      _notesController.text = match.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _bagsUsedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  String _formatBags(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final String dateStr = _dateController.text;
    final String nowStr = now.toString().split(' ')[0];
    final String timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final double bagsUsed = double.tryParse(_bagsUsedController.text) ?? 0.0;

    final record = FarmFertilizerUsageModel(
      id: _isEdit ? _existingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      date: dateStr,
      fertilizerId: _selectedFertilizerId!,
      bagsUsed: bagsUsed,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdDate: _isEdit ? _existingRecord!.createdDate : nowStr,
      createdTime: _isEdit ? _existingRecord!.createdTime : timeStr,
      lastUpdatedDate: nowStr,
      lastUpdatedTime: timeStr,
    );

    if (_isEdit) {
      await ref.read(farmChemicalUsagesProvider.notifier).updateUsage(record);
    } else {
      await ref.read(farmChemicalUsagesProvider.notifier).addUsage(record);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Usage log updated successfully' : 'Usage logged successfully'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncInventory = ref.watch(farmChemicalInventoryProvider);
    final stockMap = ref.watch(farmChemicalStockMapProvider);

    if (_isLoading || asyncInventory.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final inventory = asyncInventory.value ?? [];

    // Filter list to show active batches or the currently selected one in edit mode
    final dropdownItems = inventory.where((item) {
      final remaining = stockMap[item.id] ?? 0.0;
      final isCurrentSelected = _isEdit && item.id == _existingRecord?.fertilizerId;
      return remaining > 0 || isCurrentSelected;
    }).toList();

    // Get selected batch stock limit
    double maxAvailable = 0.0;
    if (_selectedFertilizerId != null) {
      maxAvailable = stockMap[_selectedFertilizerId] ?? 0.0;
      if (_isEdit && _selectedFertilizerId == _existingRecord?.fertilizerId) {
        maxAvailable += _existingRecord!.bagsUsed; // restore what was used in edit context
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Chemical Usage' : 'Log Chemical Usage'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  labelText: 'Date *',
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Select Chemical Fertilizer *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFertilizerId,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  hint: const Text('Select a fertilizer batch'),
                  items: dropdownItems.map((item) {
                    final remaining = stockMap[item.id] ?? 0.0;
                    final effective = _isEdit && item.id == _existingRecord?.fertilizerId
                        ? remaining + _existingRecord!.bagsUsed
                        : remaining;
                    return DropdownMenuItem<String>(
                      value: item.id,
                      child: Text('${item.name} (Stock: ${_formatBags(effective)} Bags)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedFertilizerId = val;
                      _bagsUsedController.clear(); // clear input to re-validate
                    });
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Bags Used *',
                  controller: _bagsUsedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hintText: _selectedFertilizerId == null ? 'Select fertilizer first' : 'Max available: ${_formatBags(maxAvailable)} bags',
                  readOnly: _selectedFertilizerId == null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Must be a number';
                    if (parsed <= 0) return 'Must be greater than 0';
                    if (parsed > maxAvailable) return 'Cannot exceed available stock (${_formatBags(maxAvailable)} Bags)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g. Applied on West Plot Coconut trees...',
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: _isEdit ? 'Update Log' : 'Save Log',
                  onPressed: _saveForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
