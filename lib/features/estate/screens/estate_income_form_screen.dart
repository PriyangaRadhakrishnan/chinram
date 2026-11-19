import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/estate_income_model.dart';
import '../providers/estate_income_provider.dart';

class EstateIncomeFormScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? product;
  final String? incomeId;

  const EstateIncomeFormScreen({
    super.key,
    this.category,
    this.product,
    this.incomeId,
  });

  @override
  ConsumerState<EstateIncomeFormScreen> createState() => _EstateIncomeFormScreenState();
}

class _EstateIncomeFormScreenState extends ConsumerState<EstateIncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _categoryController;
  late final TextEditingController _productController;
  final _quantityController = TextEditingController();
  String _selectedUnit = 'Kg';
  final _priceController = TextEditingController();
  final _totalController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();

  // Cardamom specific controllers
  final _greenQuantityController = TextEditingController();
  final _dryQuantityController = TextEditingController();
  final _percentController = TextEditingController(text: '0.00');

  bool get _isEdit => widget.incomeId != null;
  bool get _isOthers => (_categoryController.text.toLowerCase() == 'others') || (widget.category?.toLowerCase() == 'others');
  bool get _isCardamom => _categoryController.text.toLowerCase() == 'cardamom' || widget.category?.toLowerCase() == 'cardamom';

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.category ?? '');
    _productController = TextEditingController(text: _isOthers ? '' : (widget.product ?? ''));

    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotalOrCardamom);
    _greenQuantityController.addListener(_calculateCardamomFields);
    _dryQuantityController.addListener(_calculateCardamomFields);

    if (_isCardamom) {
      _selectedUnit = 'Kg';
    }

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIncomeData());
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotal);
    _priceController.removeListener(_calculateTotalOrCardamom);
    _greenQuantityController.removeListener(_calculateCardamomFields);
    _dryQuantityController.removeListener(_calculateCardamomFields);
    _categoryController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    _greenQuantityController.dispose();
    _dryQuantityController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    if (quantity > 0 && price > 0) {
      setState(() {
        _totalController.text = (quantity * price).toStringAsFixed(2);
      });
    } else {
      setState(() {
        _totalController.text = '0.00';
      });
    }
  }

  void _calculateTotalOrCardamom() {
    if (_isCardamom) {
      _calculateCardamomFields();
    } else {
      _calculateTotal();
    }
  }

  void _calculateCardamomFields() {
    final greenQty = double.tryParse(_greenQuantityController.text) ?? 0.0;
    final dryQty = double.tryParse(_dryQuantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    // Percent = Green Quantity / Dry Quantity
    double percent = 0.00;
    if (dryQty > 0) {
      percent = greenQty / dryQty;
    }
    _percentController.text = percent.toStringAsFixed(2);

    // Total Amount = Dry Quantity * Price Per Unit
    double totalAmount = 0.00;
    if (dryQty > 0 && price > 0) {
      totalAmount = dryQty * price;
    }
    _totalController.text = formatINR(totalAmount);
  }

  void _loadIncomeData() async {
    final service = ref.read(estateIncomeServiceProvider);
    final record = await service.getById(widget.incomeId!);
    if (record != null && mounted) {
      setState(() {
        _selectedDate = record.date;
        _categoryController.text = record.category;
        _productController.text = record.productName;
        _selectedUnit = record.unit;
        _notesController.text = record.notes ?? '';

        if (_isCardamom) {
          _greenQuantityController.text = record.greenQuantity?.toString() ?? '';
          _dryQuantityController.text = record.dryQuantity?.toString() ?? '';
          _priceController.text = record.pricePerUnit.toString();
          _calculateCardamomFields();
        } else {
          _quantityController.text = record.quantity.toString();
          _priceController.text = record.pricePerUnit.toString();
          _totalController.text = record.totalAmount.toStringAsFixed(2);
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

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final double quantity;
      final double price;
      final double total;
      final double? greenQuantity;
      final double? dryQuantity;
      final double? percent;

      if (_isCardamom) {
        greenQuantity = double.parse(_greenQuantityController.text);
        dryQuantity = double.parse(_dryQuantityController.text);
        price = double.parse(_priceController.text);
        percent = dryQuantity > 0 ? (greenQuantity / dryQuantity) : 0.0;
        total = dryQuantity * price;
        quantity = dryQuantity;
      } else {
        quantity = double.parse(_quantityController.text);
        price = double.parse(_priceController.text);
        total = quantity * price;
        greenQuantity = null;
        dryQuantity = null;
        percent = null;
      }

      final record = EstateIncomeModel(
        id: widget.incomeId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate,
        category: _categoryController.text.trim().isEmpty ? 'Others' : _categoryController.text.trim(),
        productName: _productController.text.trim(),
        quantity: quantity,
        unit: _selectedUnit,
        pricePerUnit: price,
        totalAmount: total,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        greenQuantity: greenQuantity,
        dryQuantity: dryQuantity,
        percent: percent,
      );

      final notifier = ref.read(estateIncomeListProvider.notifier);
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

  Widget _buildCardamomForm(ThemeData theme, String formattedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Date
        ListTile(
          title: Text(
            'Date: $formattedDate',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.calendar_today),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: theme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: _selectDate,
        ),
        const SizedBox(height: 20),

        // 2. Category
        CustomTextField(
          controller: _categoryController,
          labelText: 'Category',
          readOnly: true,
        ),
        const SizedBox(height: 20),

        // 3. Product Name
        CustomTextField(
          controller: _productController,
          labelText: 'Product Name',
          readOnly: true,
        ),
        const SizedBox(height: 20),

        // 4. Green Quantity
        CustomTextField(
          controller: _greenQuantityController,
          labelText: 'Green Quantity *',
          hintText: 'e.g. 380',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter green quantity';
            }
            final val = double.tryParse(value);
            if (val == null || val <= 0) {
              return 'Must be greater than zero';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // 5. Dry Quantity
        CustomTextField(
          controller: _dryQuantityController,
          labelText: 'Dry Quantity *',
          hintText: 'e.g. 61.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter dry quantity';
            }
            final val = double.tryParse(value);
            if (val == null || val <= 0) {
              return 'Must be greater than zero';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // 6. Unit
        DropdownButtonFormField<String>(
          initialValue: 'Kg',
          decoration: const InputDecoration(
            labelText: 'Unit *',
          ),
          items: const [
            DropdownMenuItem(value: 'Kg', child: Text('Kg')),
          ],
          onChanged: (val) {},
        ),
        const SizedBox(height: 20),

        // 7. Percent (Auto Calculated)
        CustomTextField(
          controller: _percentController,
          labelText: 'Percent (Auto Calculated)',
          readOnly: true,
        ),
        const SizedBox(height: 20),

        // 8. Price Per Unit (Dry Quantity)
        CustomTextField(
          controller: _priceController,
          labelText: 'Price Per Unit *',
          hintText: 'e.g. 1450',
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

        // 9. Total Amount (Auto Calculated)
        CustomTextField(
          controller: _totalController,
          labelText: 'Total Amount (Auto Calculated)',
          readOnly: true,
        ),
        const SizedBox(height: 20),

        // 10. Notes
        CustomTextField(
          controller: _notesController,
          labelText: 'Notes',
          hintText: 'Optional comments or details',
        ),
        const SizedBox(height: 32),

        // Save button
        PrimaryButton(
          text: _isEdit ? 'Update Record' : 'Add Record',
          onPressed: _saveForm,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Income' : 'Add Income'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: _isCardamom
                ? _buildCardamomForm(theme, formattedDate)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Picker Field
                      ListTile(
                        title: Text(
                          'Date: $formattedDate',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: theme.dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 20),

                      // Category Field (Pre-filled and read-only)
                      CustomTextField(
                        controller: _categoryController,
                        labelText: 'Category',
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),

                      // Product Field (Pre-filled/Read-only or custom edit text field if category is Others)
                      CustomTextField(
                        controller: _productController,
                        labelText: _isOthers ? 'Product Name (Custom) *' : 'Product Name',
                        readOnly: !_isOthers,
                        hintText: 'e.g. Robusta Parchment',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Quantity and Unit fields
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _quantityController,
                              labelText: 'Quantity *',
                              hintText: 'e.g. 150',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter quantity';
                                }
                                final val = double.tryParse(value);
                                if (val == null || val <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit *',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                                DropdownMenuItem(value: 'Gram', child: Text('Gram')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Price per Unit field
                      CustomTextField(
                        controller: _priceController,
                        labelText: 'Price Per Unit *',
                        hintText: 'e.g. 180.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter price';
                          }
                          final val = double.tryParse(value);
                          if (val == null || val <= 0) {
                            return 'Must be > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Total Amount auto-calculated read-only field
                      CustomTextField(
                        controller: _totalController,
                        labelText: 'Total Amount (Auto Calculated)',
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),

                      // Notes optional input
                      CustomTextField(
                        controller: _notesController,
                        labelText: 'Notes',
                        hintText: 'Optional comments or details',
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      PrimaryButton(
                        text: _isEdit ? 'Update Record' : 'Add Record',
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
