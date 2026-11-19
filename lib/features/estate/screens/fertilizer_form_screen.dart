import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/fertilizer_model.dart';
import '../models/organic_fertilizer_model.dart';
import '../providers/fertilizer_provider.dart';
import '../providers/organic_fertilizer_provider.dart';

class FertilizerFormScreen extends ConsumerStatefulWidget {
  final String? fertilizerId;
  final String? organicFertilizerId;
  final int initialTab;

  const FertilizerFormScreen({
    super.key,
    this.fertilizerId,
    this.organicFertilizerId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<FertilizerFormScreen> createState() => _FertilizerFormScreenState();
}

class _FertilizerFormScreenState extends ConsumerState<FertilizerFormScreen> {
  final _chemicalFormKey = GlobalKey<FormState>();
  final _organicFormKey = GlobalKey<FormState>();

  // Chemical Fertilizer Controllers & variables
  DateTime _selectedDate = DateTime.now();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  double _totalPrice = 0.0;
  FertilizerModel? _editingFertilizer;

  // Organic Fertilizer Controllers & variables
  final _organicNameController = TextEditingController();
  final _organicLoadsController = TextEditingController();
  final _organicPriceController = TextEditingController();
  String? _selectedOrganicUnit;
  double _organicTotalPrice = 0.0;
  OrganicFertilizerModel? _editingOrganic;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_updateTotalPrice);
    _organicPriceController.addListener(_updateOrganicTotalPrice);
  }

  @override
  void dispose() {
    _priceController.removeListener(_updateTotalPrice);
    _organicPriceController.removeListener(_updateOrganicTotalPrice);
    _nameController.dispose();
    _qtyController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _organicNameController.dispose();
    _organicLoadsController.dispose();
    _organicPriceController.dispose();
    super.dispose();
  }

  void _updateTotalPrice() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalPrice = price;
    });
  }

  void _updateOrganicTotalPrice() {
    final price = double.tryParse(_organicPriceController.text) ?? 0.0;
    setState(() {
      _organicTotalPrice = price;
    });
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

  void _saveChemical() async {
    if (_chemicalFormKey.currentState!.validate()) {
      final isEdit = _editingFertilizer != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingFertilizer!.createdDate : nowStr;
      final String createdT = isEdit ? _editingFertilizer!.createdTime : timeStr;

      final stockVal = int.tryParse(_stockController.text) ?? 0;

      final fertilizer = FertilizerModel(
        id: isEdit ? _editingFertilizer!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        date: _formatDateString(_selectedDate),
        name: _nameController.text.trim(),
        quantityPerBag: double.tryParse(_qtyController.text) ?? 0.0,
        unit: 'Kg',
        initialStock: stockVal,
        price: double.tryParse(_priceController.text) ?? 0.0,
        totalPrice: _totalPrice,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(fertilizerInventoryProvider.notifier).updateFertilizer(fertilizer, stockVal);
      } else {
        await ref.read(fertilizerInventoryProvider.notifier).addFertilizer(fertilizer, stockVal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Fertilizer updated successfully' : 'Fertilizer added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _saveOrganic() async {
    if (_organicFormKey.currentState!.validate()) {
      final isEdit = _editingOrganic != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingOrganic!.createdDate : nowStr;
      final String createdT = isEdit ? _editingOrganic!.createdTime : timeStr;

      final record = OrganicFertilizerModel(
        id: isEdit ? _editingOrganic!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        date: _formatDateString(_selectedDate),
        name: _organicNameController.text.trim(),
        loads: double.tryParse(_organicLoadsController.text) ?? 0.0,
        unit: _selectedOrganicUnit!,
        price: double.tryParse(_organicPriceController.text) ?? 0.0,
        totalPrice: _organicTotalPrice,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(organicFertilizerListProvider.notifier).updateOrganicFertilizer(record);
      } else {
        await ref.read(organicFertilizerListProvider.notifier).addOrganicFertilizer(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Organic Fertilizer purchase updated successfully' : 'Organic Fertilizer purchase saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  int get _initialIndex {
    if (widget.organicFertilizerId != null) return 1;
    return widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(fertilizerInventoryProvider);
    final organicListAsync = ref.watch(organicFertilizerListProvider);
    final theme = Theme.of(context);

    // Populate chemical edit data
    if (widget.fertilizerId != null && !_initialized && inventoryAsync.hasValue) {
      final list = inventoryAsync.value ?? [];
      final editFert = list.where((f) => f.id == widget.fertilizerId).firstOrNull;
      if (editFert != null) {
        _editingFertilizer = editFert;
        _selectedDate = DateTime.tryParse(editFert.date) ?? _selectedDate;
        _nameController.text = editFert.name;
        _qtyController.text = editFert.quantityPerBag.toString();
        _stockController.text = editFert.initialStock.toString();
        _priceController.text = editFert.price.toString();
        _totalPrice = editFert.price;
        _initialized = true;
      }
    }

    // Populate organic edit data
    if (widget.organicFertilizerId != null && !_initialized && organicListAsync.hasValue) {
      final list = organicListAsync.value ?? [];
      final editOrg = list.where((f) => f.id == widget.organicFertilizerId).firstOrNull;
      if (editOrg != null) {
        _editingOrganic = editOrg;
        _selectedDate = DateTime.tryParse(editOrg.date) ?? _selectedDate;
        _organicNameController.text = editOrg.name;
        _organicLoadsController.text = editOrg.loads.toString();
        _selectedOrganicUnit = editOrg.unit;
        _organicPriceController.text = editOrg.price.toString();
        _organicTotalPrice = editOrg.price;
        _initialized = true;
      }
    }

    final isEditing = widget.fertilizerId != null || widget.organicFertilizerId != null;

    return DefaultTabController(
      initialIndex: _initialIndex,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.fertilizerId != null
                ? 'Edit Fertilizer'
                : widget.organicFertilizerId != null
                    ? 'Edit Organic Fertilizer'
                    : 'Add Fertilizer',
          ),
          centerTitle: true,
          bottom: isEditing
              ? null
              : const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                  tabs: [
                    Tab(text: 'Fertilizer'),
                    Tab(text: 'Organic Fertilizer'),
                  ],
                ),
        ),
        body: SafeArea(
          child: TabBarView(
            physics: isEditing ? const NeverScrollableScrollPhysics() : null,
            children: [
              // Tab 1: Chemical Fertilizer Form
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _chemicalFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chemical Fertilizer Specifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
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

                      // Name
                      const Text('Fertilizer Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Urea',
                          prefixIcon: Icon(Icons.grass),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter fertilizer name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Quantity & Unit row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quantity Per Bag *', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _qtyController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 50.0',
                                    prefixIcon: Icon(Icons.scale),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Enter quantity';
                                    if (double.tryParse(val) == null) return 'Invalid number';
                                    if (double.parse(val) <= 0) return 'Must be > 0';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Unit', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  initialValue: 'Kg',
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme.disabledColor.withValues(alpha: 0.05),
                                    prefixIcon: const Icon(Icons.line_weight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stock
                      const Text('Stock (Number of Bags) *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 100',
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter stock bags quantity';
                          if (int.tryParse(val) == null) return 'Enter a whole number';
                          if (int.parse(val) < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Price
                      const Text('Price (₹) *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 5000.0',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter price';
                          if (double.tryParse(val) == null) return 'Invalid number';
                          if (double.parse(val) < 0) return 'Must be >= 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Total Price Summary
                      Card(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Price (Calculated)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '₹${_totalPrice.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
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
                              onPressed: _saveChemical,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(widget.fertilizerId == null ? 'Add Fertilizer' : 'Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tab 2: Organic Fertilizer Form
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _organicFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organic Fertilizer Specifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
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

                      // Organic Name
                      const Text('Organic Fertilizer Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _organicNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Cow Dung',
                          prefixIcon: Icon(Icons.grass),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter organic fertilizer name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Number of Loads (decimal > 0)
                      const Text('Number of Loads *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _organicLoadsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 2.5',
                          prefixIcon: Icon(Icons.local_shipping),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter loads count';
                          final parsed = double.tryParse(val);
                          if (parsed == null) return 'Please enter a valid number';
                          if (parsed <= 0) return 'Loads count must be greater than zero';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Unit Dropdown: Tractor, Pickup, 407, Lorry
                      const Text('Unit *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedOrganicUnit,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        hint: const Text('Select a unit type'),
                        items: const [
                          DropdownMenuItem(value: 'Tractor', child: Text('Tractor')),
                          DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                          DropdownMenuItem(value: '407', child: Text('407')),
                          DropdownMenuItem(value: 'Lorry', child: Text('Lorry')),
                        ],
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please select unit type';
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _selectedOrganicUnit = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Price
                      const Text('Price (₹) *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _organicPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 15000.0',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter price';
                          final parsed = double.tryParse(val);
                          if (parsed == null) return 'Please enter a valid number';
                          if (parsed <= 0) return 'Price must be greater than zero';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Total Price Summary (equal to price)
                      Card(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Price (Calculated)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '₹${_organicTotalPrice.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
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
                              onPressed: _saveOrganic,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(widget.organicFertilizerId == null ? 'Add Organic' : 'Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
