import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/farm_fertilizer_model.dart';
import '../providers/farm_fertilizer_provider.dart';

class FarmFertilizerFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const FarmFertilizerFormScreen({super.key, this.id});

  @override
  ConsumerState<FarmFertilizerFormScreen> createState() => _FarmFertilizerFormScreenState();
}

class _FarmFertilizerFormScreenState extends ConsumerState<FarmFertilizerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _isLoading = false;

  final _dateController = TextEditingController();
  final _nameController = TextEditingController();
  final _qtyPerBagController = TextEditingController(text: '50.0'); // default
  final _unitController = TextEditingController(text: 'Kg'); // read-only
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  FarmFertilizerModel? _existingRecord;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.id != null;
    _dateController.text = _selectedDate.toString().split(' ')[0];

    // Whenever price is updated, sync total price to price
    _priceController.addListener(() {
      final priceVal = double.tryParse(_priceController.text) ?? 0.0;
      _totalPriceController.text = priceVal.toStringAsFixed(2);
    });

    if (_isEdit) {
      _loadExisting();
    }
  }

  void _loadExisting() async {
    setState(() => _isLoading = true);
    final list = await ref.read(farmChemicalInventoryProvider.future);
    final match = list.where((item) => item.id == widget.id).firstOrNull;
    if (match != null) {
      _existingRecord = match;
      _selectedDate = DateTime.parse(match.date);
      _dateController.text = match.date;
      _nameController.text = match.name;
      _qtyPerBagController.text = match.quantityPerBag.toString();
      _unitController.text = match.unit;
      _stockController.text = match.initialStock % 1 == 0 ? match.initialStock.toInt().toString() : match.initialStock.toString();
      _priceController.text = match.price.toString();
      _totalPriceController.text = match.totalPrice.toString();
      _notesController.text = match.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _qtyPerBagController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _totalPriceController.dispose();
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

    final double quantityPerBag = double.tryParse(_qtyPerBagController.text) ?? 50.0;
    final double initialStock = double.tryParse(_stockController.text) ?? 0.0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final double totalPrice = price; // Total Price = Price

    final record = FarmFertilizerModel(
      id: _isEdit ? _existingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      date: dateStr,
      name: _nameController.text.trim(),
      quantityPerBag: quantityPerBag,
      unit: _unitController.text.trim(),
      initialStock: initialStock,
      price: price,
      totalPrice: totalPrice,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdDate: _isEdit ? _existingRecord!.createdDate : nowStr,
      createdTime: _isEdit ? _existingRecord!.createdTime : timeStr,
      lastUpdatedDate: nowStr,
      lastUpdatedTime: timeStr,
    );

    if (_isEdit) {
      await ref.read(farmChemicalInventoryProvider.notifier).updateChemical(record);
    } else {
      await ref.read(farmChemicalInventoryProvider.notifier).addChemical(record);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Fertilizer updated successfully' : 'Fertilizer added successfully'), behavior: SnackBarBehavior.floating),
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
        title: Text(_isEdit ? 'Edit Chemical Fertilizer' : 'Add Chemical Fertilizer'),
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
                  labelText: 'Fertilizer Name *',
                  controller: _nameController,
                  hintText: 'e.g. Urea, Potash',
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        labelText: 'Quantity Per Bag *',
                        controller: _qtyPerBagController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        labelText: 'Unit',
                        controller: _unitController,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Stock (Number of Bags) *',
                  controller: _stockController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hintText: 'e.g. 100 or 12.5',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Must be a number';
                    if (parsed < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Price (₹) *',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hintText: 'Total price of purchase',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Must be a number';
                    if (parsed < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Total Price (₹)',
                  controller: _totalPriceController,
                  readOnly: true,
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
                  text: _isEdit ? 'Update Fertilizer' : 'Save Fertilizer',
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
