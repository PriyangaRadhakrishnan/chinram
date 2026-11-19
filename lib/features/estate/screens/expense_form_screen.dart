import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/weekly_expense_model.dart';
import '../providers/weekly_expense_provider.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({
    super.key,
    this.expenseId,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  final _customCategoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _initialized = false;
  WeeklyExpenseModel? _editingExpense;

  @override
  void dispose() {
    _customCategoryController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = _editingExpense != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingExpense!.createdDate : nowStr;
      final String createdT = isEdit ? _editingExpense!.createdTime : timeStr;

      final expense = WeeklyExpenseModel(
        id: isEdit ? _editingExpense!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        date: _formatDateString(_selectedDate),
        category: _selectedCategory!,
        customCategoryName: _selectedCategory == 'Others' ? _customCategoryController.text.trim() : null,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(weeklyExpenseListProvider.notifier).updateExpense(expense);
      } else {
        await ref.read(weeklyExpenseListProvider.notifier).addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Other Expense updated successfully' : 'Other Expense recorded successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseListAsync = ref.watch(weeklyExpenseListProvider);
    final theme = Theme.of(context);

    // Populate edit data
    if (widget.expenseId != null && !_initialized && expenseListAsync.hasValue) {
      final list = expenseListAsync.value ?? [];
      final editExpense = list.where((e) => e.id == widget.expenseId).firstOrNull;
      if (editExpense != null) {
        _editingExpense = editExpense;
        _selectedDate = DateTime.tryParse(editExpense.date) ?? _selectedDate;
        _selectedCategory = editExpense.category;
        _customCategoryController.text = editExpense.customCategoryName ?? '';
        _amountController.text = editExpense.amount.toString();
        _notesController.text = editExpense.notes ?? '';
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseId == null ? 'Add Other Expense' : 'Edit Other Expense'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Expense Details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 24),

                // Date field
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

                // Category field
                const Text('Expense Category *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  hint: const Text('Select a category'),
                  items: const [
                    DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                    DropdownMenuItem(value: 'Brush Cutter', child: Text('Brush Cutter')),
                    DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Pest / Insecticide', child: Text('Pest / Insecticide')),
                    DropdownMenuItem(value: 'Others', child: Text('Others')),
                  ],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please select an expense category';
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Custom category field
                if (_selectedCategory == 'Others') ...[
                  const Text('Custom Category Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter custom category name',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    validator: (val) {
                      if (_selectedCategory == 'Others' && (val == null || val.trim().isEmpty)) {
                        return 'Please enter a custom category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Amount field
                const Text('Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 1500.00',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(val) == null) return 'Please enter a valid number';
                    if (double.parse(val) <= 0) return 'Amount must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Notes field
                const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add notes or descriptions...',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 40),

                // Action buttons
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
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.expenseId == null ? 'Add Expense' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
