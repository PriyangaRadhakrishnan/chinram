import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/farm_expense_model.dart';
import '../providers/farm_expense_provider.dart';

class FarmExpenseFormScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? subCategory;
  final String? expenseId;

  const FarmExpenseFormScreen({
    super.key,
    this.category,
    this.subCategory,
    this.expenseId,
  });

  @override
  ConsumerState<FarmExpenseFormScreen> createState() => _FarmExpenseFormScreenState();
}

class _FarmExpenseFormScreenState extends ConsumerState<FarmExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();

  late final TextEditingController _categoryController;
  late final TextEditingController _subCategoryController;
  final _notesController = TextEditingController();
  final _totalController = TextEditingController(text: '₹0.00');

  // Coconut (Kai Vettu) specific controllers
  final _vettuCountController = TextEditingController();
  final _vettuAmountController = TextEditingController();
  final _chithuCountController = TextEditingController();
  final _chithuAmountController = TextEditingController();
  final _teaExpenseController = TextEditingController();
  final List<Map<String, TextEditingController>> _otherExpensesControllers = [];

  // Milk Feed/Grass / Others specific controllers
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _amountController = TextEditingController(); // For direct amount entries

  bool get _isEdit => widget.expenseId != null;

  String get _currentCategory {
    if (_isEdit) {
      return _categoryController.text;
    }
    return widget.category ?? 'Others';
  }

  String? get _currentSubCategory {
    if (_isEdit) {
      return _subCategoryController.text.isEmpty ? null : _subCategoryController.text;
    }
    return widget.subCategory?.isEmpty ?? true ? null : widget.subCategory;
  }

  bool get _isCoconut => _currentCategory.toLowerCase() == 'coconut';
  bool get _isMilk => _currentCategory.toLowerCase() == 'milk';
  bool get _isOthers => _currentCategory.toLowerCase() == 'others';

  @override
  void initState() {
    super.initState();

    _categoryController = TextEditingController(text: widget.category ?? '');
    _subCategoryController = TextEditingController(text: widget.subCategory ?? '');

    // Default setups
    if (!_isEdit) {
      if (_isMilk && _currentSubCategory != null) {
        if (_currentSubCategory!.toLowerCase() == 'feed') {
          _unitController.text = 'Sacks';
        } else if (_currentSubCategory!.toLowerCase() == 'grass') {
          _unitController.text = 'Kg';
        }
      }
    }

    // Add listeners for auto-calculations
    if (_isCoconut) {
      _vettuAmountController.addListener(_calculateCoconutTotal);
      _chithuAmountController.addListener(_calculateCoconutTotal);
      _teaExpenseController.addListener(_calculateCoconutTotal);
    } else {
      _amountController.addListener(_calculateDirectTotal);
    }

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpenseData());
    }
  }

  @override
  void dispose() {
    _vettuAmountController.removeListener(_calculateCoconutTotal);
    _chithuAmountController.removeListener(_calculateCoconutTotal);
    _teaExpenseController.removeListener(_calculateCoconutTotal);
    _amountController.removeListener(_calculateDirectTotal);

    for (final ctrl in _otherExpensesControllers) {
      ctrl['name']?.dispose();
      ctrl['amount']?.dispose();
    }

    _categoryController.dispose();
    _subCategoryController.dispose();
    _notesController.dispose();
    _totalController.dispose();

    _vettuCountController.dispose();
    _vettuAmountController.dispose();
    _chithuCountController.dispose();
    _chithuAmountController.dispose();
    _teaExpenseController.dispose();

    _productNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _amountController.dispose();
    
    super.dispose();
  }

  void _calculateCoconutTotal() {
    final vettu = double.tryParse(_vettuAmountController.text) ?? 0.0;
    final chithu = double.tryParse(_chithuAmountController.text) ?? 0.0;
    final tea = double.tryParse(_teaExpenseController.text) ?? 0.0;

    double otherTotal = 0.0;
    for (final ctrl in _otherExpensesControllers) {
      otherTotal += double.tryParse(ctrl['amount']!.text) ?? 0.0;
    }

    setState(() {
      _totalController.text = formatINR(vettu + chithu + tea + otherTotal);
    });
  }

  void _calculateDirectTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _totalController.text = formatINR(amount);
    });
  }

  void _addOtherExpenseRow() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    
    nameCtrl.addListener(_calculateCoconutTotal);
    amountCtrl.addListener(_calculateCoconutTotal);

    setState(() {
      _otherExpensesControllers.add({
        'name': nameCtrl,
        'amount': amountCtrl,
      });
    });
  }

  void _removeOtherExpenseRow(Map<String, TextEditingController> item) {
    setState(() {
      item['name']?.dispose();
      item['amount']?.dispose();
      _otherExpensesControllers.remove(item);
      _calculateCoconutTotal();
    });
  }

  void _loadExpenseData() async {
    final service = ref.read(farmExpenseServiceProvider);
    final record = await service.getById(widget.expenseId!);
    if (record != null && mounted) {
      setState(() {
        _selectedDate = record.date;
        _categoryController.text = record.category;
        _subCategoryController.text = record.subCategory ?? '';
        _notesController.text = record.notes ?? '';
        _totalController.text = formatINR(record.amount);

        if (_isCoconut) {
          _vettuCountController.text = record.vettuWorkersCount?.toString() ?? '';
          _vettuAmountController.text = record.vettuWorkerAmount?.toStringAsFixed(0) ?? '';
          _chithuCountController.text = record.chithuWorkersCount?.toString() ?? '';
          _chithuAmountController.text = record.chithuWorkerAmount?.toStringAsFixed(0) ?? '';
          _teaExpenseController.text = record.teaExpense?.toStringAsFixed(0) ?? '';

          if (record.otherExpenses != null) {
            for (final item in record.otherExpenses!) {
              final nameCtrl = TextEditingController(text: item.name);
              final amountCtrl = TextEditingController(text: item.amount.toStringAsFixed(0));
              
              nameCtrl.addListener(_calculateCoconutTotal);
              amountCtrl.addListener(_calculateCoconutTotal);

              _otherExpensesControllers.add({
                'name': nameCtrl,
                'amount': amountCtrl,
              });
            }
          }
          _calculateCoconutTotal();
        } else {
          _amountController.text = record.amount.toStringAsFixed(0);
          _productNameController.text = record.productName ?? '';
          _quantityController.text = record.quantity?.toStringAsFixed(record.quantity! % 1 == 0 ? 0 : 2) ?? '';
          _unitController.text = record.unit ?? '';
          _calculateDirectTotal();
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
      double totalAmount = 0.0;
      
      int? vettuWorkersCount;
      double? vettuWorkerAmount;
      int? chithuWorkersCount;
      double? chithuWorkerAmount;
      double? teaExpense;
      List<OtherExpenseItem>? otherExpenses;

      String? productName;
      double? quantity;
      String? unit;

      if (_isCoconut) {
        vettuWorkersCount = int.tryParse(_vettuCountController.text);
        vettuWorkerAmount = double.tryParse(_vettuAmountController.text) ?? 0.0;
        chithuWorkersCount = int.tryParse(_chithuCountController.text);
        chithuWorkerAmount = double.tryParse(_chithuAmountController.text) ?? 0.0;
        teaExpense = double.tryParse(_teaExpenseController.text) ?? 0.0;

        otherExpenses = [];
        double otherTotal = 0.0;
        for (final ctrl in _otherExpensesControllers) {
          final name = ctrl['name']!.text.trim();
          final amount = double.tryParse(ctrl['amount']!.text) ?? 0.0;
          if (name.isNotEmpty && amount > 0) {
            otherExpenses.add(OtherExpenseItem(name: name, amount: amount));
            otherTotal += amount;
          }
        }

        totalAmount = vettuWorkerAmount + chithuWorkerAmount + teaExpense + otherTotal;
      } else {
        totalAmount = double.parse(_amountController.text);
        
        if (_isMilk) {
          final isFeedOrGrass = _currentSubCategory?.toLowerCase() == 'feed' || _currentSubCategory?.toLowerCase() == 'grass';
          if (isFeedOrGrass) {
            productName = _productNameController.text.trim();
            quantity = double.tryParse(_quantityController.text);
            unit = _unitController.text.trim();
          } else {
            productName = _currentSubCategory;
          }
        } else if (_isOthers) {
          productName = _productNameController.text.trim();
        } else {
          productName = _currentCategory;
        }
      }

      final record = FarmExpenseModel(
        id: widget.expenseId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate,
        category: _currentCategory,
        subCategory: _currentSubCategory,
        amount: totalAmount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        vettuWorkersCount: vettuWorkersCount,
        vettuWorkerAmount: vettuWorkerAmount,
        chithuWorkersCount: chithuWorkersCount,
        chithuWorkerAmount: chithuWorkerAmount,
        teaExpense: teaExpense,
        otherExpenses: otherExpenses,
        productName: productName,
        quantity: quantity,
        unit: unit,
      );

      final notifier = ref.read(farmExpenseListProvider.notifier);
      if (_isEdit) {
        await notifier.updateExpense(record);
      } else {
        await notifier.addExpense(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Expense record updated successfully' : 'Expense record logged successfully'),
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

    // Form setup based on categories
    final isFeedOrGrass = _isMilk && (_currentSubCategory?.toLowerCase() == 'feed' || _currentSubCategory?.toLowerCase() == 'grass');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Farm Expense' : 'Add Farm Expense'),
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

                        CustomTextField(
                          labelText: 'Category',
                          controller: _categoryController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        if (_currentSubCategory != null) ...[
                          CustomTextField(
                            labelText: 'Sub-Category',
                            controller: _subCategoryController,
                            readOnly: true,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ==========================================
                        // COCONUT FORM
                        // ==========================================
                        if (_isCoconut) ...[
                          // Vettu Workers Section
                          Text(
                            'Vettu Workers',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          context.isDesktop || context.isTablet
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: 'Number of Workers',
                                        controller: _vettuCountController,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: 'Amount (₹) *',
                                        controller: _vettuAmountController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) return 'Required';
                                          if (double.tryParse(value) == null) return 'Must be number';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    CustomTextField(
                                      labelText: 'Number of Workers',
                                      controller: _vettuCountController,
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      labelText: 'Amount (₹) *',
                                      controller: _vettuAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Required';
                                        if (double.tryParse(value) == null) return 'Must be number';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 24),

                          // Chithu Workers Section
                          Text(
                            'Chithu Workers',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          context.isDesktop || context.isTablet
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: 'Number of Workers',
                                        controller: _chithuCountController,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: 'Amount (₹) *',
                                        controller: _chithuAmountController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) return 'Required';
                                          if (double.tryParse(value) == null) return 'Must be number';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    CustomTextField(
                                      labelText: 'Number of Workers',
                                      controller: _chithuCountController,
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      labelText: 'Amount (₹) *',
                                      controller: _chithuAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Required';
                                        if (double.tryParse(value) == null) return 'Must be number';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 24),

                          // Tea Expense
                          CustomTextField(
                            labelText: 'Tea Expense *',
                            controller: _teaExpenseController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Must be number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Dynamic Other Expenses Section
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                'Other Expenses (Optional)',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Other Expense'),
                                onPressed: _addOtherExpenseRow,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _otherExpensesControllers.length,
                            itemBuilder: (context, index) {
                              final item = _otherExpensesControllers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: context.isDesktop || context.isTablet
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: 'Expense Name',
                                              controller: item['name'],
                                              hintText: 'e.g. Transport, Knife Repair',
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: 'Expense Amount (₹)',
                                              controller: item['amount'],
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                                            onPressed: () => _removeOtherExpenseRow(item),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          CustomTextField(
                                            labelText: 'Expense Name',
                                            controller: item['name'],
                                            hintText: 'e.g. Transport, Knife Repair',
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomTextField(
                                                  labelText: 'Expense Amount (₹)',
                                                  controller: item['amount'],
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                                                onPressed: () => _removeOtherExpenseRow(item),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24, thickness: 1),
                                        ],
                                      ),
                              );
                            },
                          ),
                          const Divider(height: 32),
                        ],

                        // ==========================================
                        // MILK (FEED & GRASS) FORM
                        // ==========================================
                        if (isFeedOrGrass) ...[
                          CustomTextField(
                            labelText: _currentSubCategory!.toLowerCase() == 'feed' ? 'Feed Name *' : 'Grass Name *',
                            controller: _productNameController,
                            hintText: _currentSubCategory!.toLowerCase() == 'feed' ? 'e.g. Rice Bran, Coarse feed' : 'e.g. Napier, Cumbu Napier',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  labelText: 'Quantity *',
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Must be number';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  labelText: 'Unit (e.g. Sacks, Kg) *',
                                  controller: _unitController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ==========================================
                        // CUSTOM PURPOSE FORM (Others Category)
                        // ==========================================
                        if (_isOthers) ...[
                          CustomTextField(
                            labelText: 'Purpose / Details *',
                            controller: _productNameController,
                            hintText: 'e.g. Fence Repair, Water Tank Cleaning',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ==========================================
                        // DIRECT AMOUNT FIELD
                        // ==========================================
                        if (!_isCoconut) ...[
                          CustomTextField(
                            labelText: 'Expense Amount (₹) *',
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Must be number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ==========================================
                        // TOTAL AMOUNT READONLY
                        // ==========================================
                        CustomTextField(
                          labelText: 'Total Calculated Expense',
                          controller: _totalController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // ==========================================
                        // NOTES FIELD
                        // ==========================================
                        CustomTextField(
                          labelText: 'Notes (Optional)',
                          controller: _notesController,
                          hintText: 'Add extra details about this expense...',
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: _isEdit ? 'Update Expense' : 'Log Expense',
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
