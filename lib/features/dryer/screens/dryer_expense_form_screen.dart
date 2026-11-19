import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/dryer_expense_model.dart';
import '../providers/dryer_expense_provider.dart';
import '../utils/dryer_calculator.dart';
import '../widgets/dryer_info_widgets.dart';

class DryerExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const DryerExpenseFormScreen({
    super.key,
    this.expenseId,
  });

  @override
  ConsumerState<DryerExpenseFormScreen> createState() =>
      _DryerExpenseFormScreenState();
}

class _DryerExpenseFormScreenState
    extends ConsumerState<DryerExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DryerExpense? _existingExpense;
  bool _isLoading = false;
  String? _loadError;
  bool _isSaving = false;

  bool get _isEditMode => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpense());
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    try {
      final service = ref.read(dryerExpenseServiceProvider);
      final expense = await service.getExpenseById(widget.expenseId!);
      if (!mounted) return;
      if (expense == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Expense record not found.';
        });
        return;
      }

      _selectedDate = expense.date;
      _categoryController.text = expense.category;
      _amountController.text =
          DryerCalculator.formatNumber(expense.amount, maxDecimals: 4);
      _notesController.text = expense.notes ?? '';

      setState(() {
        _existingExpense = expense;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;
    if (_isEditMode && _existingExpense == null) return;
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || !parsedAmount.isFinite || parsedAmount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(dryerExpensesProvider.notifier);
      if (_isEditMode) {
        await notifier.updateExpense(
          existingExpense: _existingExpense!,
          date: _selectedDate,
          category: _categoryController.text,
          amount: parsedAmount,
          notes: _notesController.text,
        );
      } else {
        await notifier.addExpense(
          date: _selectedDate,
          category: _categoryController.text,
          amount: parsedAmount,
          notes: _notesController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Expense updated successfully'
                : 'Expense saved successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save expense: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Other Expense' : 'Add Other Expense'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading expense record...')
            : _loadError != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to Load Expense',
                    description: _loadError!,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                margin: EdgeInsets.zero,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: theme.dividerColor),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const DryerSectionHeader(
                                        icon: Icons.receipt_long_outlined,
                                        title: 'Expense Details',
                                      ),
                                      const SizedBox(height: 20),

                                      // 1. Date
                                      InkWell(
                                        onTap: _pickDate,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Date *',
                                            prefixIcon: Icon(
                                              Icons.calendar_today_outlined,
                                            ),
                                            suffixIcon:
                                                Icon(Icons.arrow_drop_down),
                                          ),
                                          child: Text(
                                            DryerCalculator.formatDate(
                                              _selectedDate,
                                            ),
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // 2. Expense Category (Free text)
                                      TextFormField(
                                        controller: _categoryController,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: const InputDecoration(
                                          labelText: 'Expense Category *',
                                          hintText:
                                              'e.g. Electricity, Transport, Maintenance',
                                          prefixIcon:
                                              Icon(Icons.category_outlined),
                                        ),
                                        validator: (val) =>
                                            DryerCalculator.validateRequiredText(
                                          val,
                                          'Expense category',
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // 3. Amount (₹)
                                      TextFormField(
                                        controller: _amountController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Amount (₹) *',
                                          hintText: 'e.g. 1500.50',
                                          prefixIcon:
                                              Icon(Icons.currency_rupee),
                                        ),
                                        validator: (val) =>
                                            DryerCalculator.validateNumericInput(
                                          val,
                                          fieldName: 'Amount',
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // 4. Notes (Optional multiline)
                                      TextFormField(
                                        controller: _notesController,
                                        minLines: 3,
                                        maxLines: 5,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: const InputDecoration(
                                          labelText: 'Notes (Optional)',
                                          hintText:
                                              'Add additional details or remarks...',
                                          prefixIcon:
                                              Icon(Icons.notes_outlined),
                                          alignLabelWithHint: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                text: _isEditMode
                                    ? 'Update Expense'
                                    : 'Save Expense',
                                isLoading: _isSaving,
                                onPressed: _saveForm,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
