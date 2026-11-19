import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/farm_organic_fertilizer_model.dart';
import '../providers/farm_fertilizer_provider.dart';

class FarmOrganicFertilizerFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const FarmOrganicFertilizerFormScreen({super.key, this.id});

  @override
  ConsumerState<FarmOrganicFertilizerFormScreen> createState() => _FarmOrganicFertilizerFormScreenState();
}

class _FarmOrganicFertilizerFormScreenState extends ConsumerState<FarmOrganicFertilizerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _isLoading = false;

  final _dateController = TextEditingController();
  final _nameController = TextEditingController();
  final _loadsController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _vehicleType = 'Tractor'; // default
  DateTime _selectedDate = DateTime.now();
  FarmOrganicFertilizerModel? _existingRecord;

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
    final list = await ref.read(farmOrganicInventoryProvider.future);
    final match = list.where((item) => item.id == widget.id).firstOrNull;
    if (match != null) {
      _existingRecord = match;
      _selectedDate = DateTime.parse(match.date);
      _dateController.text = match.date;
      _nameController.text = match.name;
      _loadsController.text = match.loads % 1 == 0 ? match.loads.toInt().toString() : match.loads.toString();
      _vehicleType = match.unit;
      _priceController.text = match.price.toString();
      _notesController.text = match.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _loadsController.dispose();
    _priceController.dispose();
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

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final String dateStr = _dateController.text;
    final String nowStr = now.toString().split(' ')[0];
    final String timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final double loads = double.tryParse(_loadsController.text) ?? 0.0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;

    final record = FarmOrganicFertilizerModel(
      id: _isEdit ? _existingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      date: dateStr,
      name: _nameController.text.trim(),
      loads: loads,
      unit: _vehicleType,
      price: price,
      totalPrice: price, // Equal to price
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdDate: _isEdit ? _existingRecord!.createdDate : nowStr,
      createdTime: _isEdit ? _existingRecord!.createdTime : timeStr,
      lastUpdatedDate: nowStr,
      lastUpdatedTime: timeStr,
    );

    if (_isEdit) {
      await ref.read(farmOrganicInventoryProvider.notifier).updateOrganic(record);
    } else {
      await ref.read(farmOrganicInventoryProvider.notifier).addOrganic(record);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Organic fertilizer updated successfully' : 'Organic fertilizer added successfully'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Organic Fertilizer' : 'Add Organic Fertilizer'),
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
                CustomTextField(
                  labelText: 'Organic Fertilizer Name *',
                  controller: _nameController,
                  hintText: 'e.g. Cow Dung, Goat Manure',
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Number of Loads *',
                  controller: _loadsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hintText: 'e.g. 5 or 2.5',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Must be a number';
                    if (parsed < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Vehicle Type *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tractor', child: Text('Tractor')),
                    DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                    DropdownMenuItem(value: '407', child: Text('407')),
                    DropdownMenuItem(value: 'Lorry', child: Text('Lorry')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _vehicleType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Price (₹) *',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hintText: 'Purchase amount',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Must be a number';
                    if (parsed < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add extra details...',
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: _isEdit ? 'Update Purchase' : 'Save Purchase',
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
