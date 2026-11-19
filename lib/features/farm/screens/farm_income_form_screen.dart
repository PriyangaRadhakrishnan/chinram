import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/farm_income_model.dart';
import '../providers/farm_income_provider.dart';

class FarmIncomeFormScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? incomeId;

  const FarmIncomeFormScreen({
    super.key,
    this.category,
    this.incomeId,
  });

  @override
  ConsumerState<FarmIncomeFormScreen> createState() => _FarmIncomeFormScreenState();
}

class _FarmIncomeFormScreenState extends ConsumerState<FarmIncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  
  // Weekly milk period dates
  DateTime _selectedFromDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _selectedToDate = DateTime.now();

  late final TextEditingController _categoryController;
  late final TextEditingController _productController;
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalController = TextEditingController(text: '₹0.00');
  final _notesController = TextEditingController();

  bool get _isEdit => widget.incomeId != null;
  
  String get _currentCategory {
    if (_isEdit) {
      return _categoryController.text;
    }
    return widget.category ?? 'Others';
  }

  bool get _isMilk => _currentCategory.toLowerCase() == 'milk';
  bool get _isCoconut => _currentCategory.toLowerCase() == 'coconut';
  bool get _isMango => _currentCategory.toLowerCase() == 'mango';
  bool get _isOthers => _currentCategory.toLowerCase() == 'others';

  @override
  void initState() {
    super.initState();
    
    _categoryController = TextEditingController(text: widget.category ?? '');
    _productController = TextEditingController();

    // Default setups
    if (!_isEdit) {
      if (_isCoconut) {
        _productController.text = 'Coconut';
        _unitController.text = 'Pcs';
      } else if (_isMango) {
        _productController.text = 'Mango';
        _unitController.text = 'Kg';
      } else if (_isMilk) {
        _productController.text = 'Milk';
        _unitController.text = 'Litres';
      } else {
        _unitController.text = 'Kg'; // Default unit for Others
      }
    }

    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIncomeData());
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _priceController.removeListener(_calculateTotal);
    _categoryController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    if (quantity > 0 && price > 0) {
      setState(() {
        _totalController.text = formatINR(quantity * price);
      });
    } else {
      setState(() {
        _totalController.text = '₹0.00';
      });
    }
  }

  void _loadIncomeData() async {
    final service = ref.read(farmIncomeServiceProvider);
    final record = await service.getById(widget.incomeId!);
    if (record != null && mounted) {
      setState(() {
        _selectedDate = record.date;
        _categoryController.text = record.category;
        _productController.text = record.productName;
        _quantityController.text = record.quantity.toStringAsFixed(record.quantity % 1 == 0 ? 0 : 2);
        _unitController.text = record.unit;
        _priceController.text = record.pricePerUnit.toStringAsFixed(record.pricePerUnit % 1 == 0 ? 0 : 2);
        _notesController.text = record.notes ?? '';
        _totalController.text = formatINR(record.totalAmount);
        
        if (record.fromDate != null) {
          _selectedFromDate = record.fromDate!;
        }
        if (record.toDate != null) {
          _selectedToDate = record.toDate!;
        }
      });
    }
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
      });
    }
  }

  void _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedFromDate = picked;
        // Automatically default To Date to 6 days after (1 week period)
        _selectedToDate = _selectedFromDate.add(const Duration(days: 6));
      });
    }
  }

  void _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedToDate,
      firstDate: _selectedFromDate, // Must not be before From Date
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedToDate = picked;
      });
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final total = quantity * price;

      final record = FarmIncomeModel(
        id: widget.incomeId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: _isMilk ? _selectedToDate : _selectedDate,
        category: _currentCategory,
        productName: _isOthers ? _productController.text.trim() : _currentCategory,
        quantity: quantity,
        unit: _unitController.text.trim(),
        pricePerUnit: price,
        totalAmount: total,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        fromDate: _isMilk ? _selectedFromDate : null,
        toDate: _isMilk ? _selectedToDate : null,
      );

      final notifier = ref.read(farmIncomeListProvider.notifier);
      if (_isEdit) {
        await notifier.updateIncome(record);
      } else {
        await notifier.addIncome(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Income record updated successfully' : 'Income record logged successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _formatDate(_selectedDate);
    final formattedFromDate = _formatDate(_selectedFromDate);
    final formattedToDate = _formatDate(_selectedToDate);

    // Label customizations
    String quantityLabel = 'Quantity *';
    String priceLabel = 'Price Per Unit *';
    String quantityHint = 'e.g. 100';
    String priceHint = 'e.g. 50';

    if (_isCoconut) {
      quantityLabel = 'Number of Coconuts *';
      priceLabel = 'Price Per Coconut (₹) *';
      quantityHint = 'e.g. 850';
      priceHint = 'e.g. 18.50';
    } else if (_isMango) {
      quantityLabel = 'Quantity (Kg) *';
      priceLabel = 'Price Per Kg (₹) *';
      quantityHint = 'e.g. 250';
      priceHint = 'e.g. 60';
    } else if (_isMilk) {
      quantityLabel = 'Total Litres *';
      priceLabel = 'Rate Per Litre (₹) *';
      quantityHint = 'e.g. 140';
      priceHint = 'e.g. 42';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Farm Income' : 'Add Farm Income'),
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
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date picker row
                        if (_isMilk) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'From: $formattedFromDate',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  trailing: const Icon(Icons.calendar_today, size: 18),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: theme.dividerColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onTap: _selectFromDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'To: $formattedToDate',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  trailing: const Icon(Icons.calendar_today, size: 18),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: theme.dividerColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onTap: _selectToDate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ] else ...[
                          ListTile(
                            title: Text(
                              'Date: $formattedDate',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Category
                        CustomTextField(
                          labelText: 'Category',
                          controller: _categoryController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Product Name
                        if (_isOthers)
                          CustomTextField(
                            labelText: 'Product Name *',
                            controller: _productController,
                            hintText: 'e.g. Honey, Eggs, Guava',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a product name';
                              }
                              return null;
                            },
                          )
                        else
                          CustomTextField(
                            labelText: 'Product Name',
                            controller: _productController,
                            readOnly: true,
                          ),
                        const SizedBox(height: 20),

                        // Quantity
                        CustomTextField(
                          labelText: quantityLabel,
                          controller: _quantityController,
                          hintText: quantityHint,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter quantity';
                            }
                            final val = double.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'Must be greater than zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Unit
                        if (_isOthers) ...[
                          CustomTextField(
                            labelText: 'Unit (e.g. Kg, Pcs, Litres) *',
                            controller: _unitController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a unit';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Price
                        CustomTextField(
                          labelText: priceLabel,
                          controller: _priceController,
                          hintText: priceHint,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter price per unit';
                            }
                            final val = double.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'Must be greater than zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Total Amount (Auto Calculated)
                        CustomTextField(
                          labelText: 'Total Amount',
                          controller: _totalController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Notes
                        CustomTextField(
                          labelText: 'Notes (Optional)',
                          controller: _notesController,
                          hintText: 'Add additional collection details...',
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: _isEdit ? 'Update Entry' : 'Log Income',
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
