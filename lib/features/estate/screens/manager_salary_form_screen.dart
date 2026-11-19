import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/manager_salary_model.dart';
import '../providers/manager_salary_provider.dart';

class ManagerSalaryFormScreen extends ConsumerStatefulWidget {
  final String? managerSalaryId;

  const ManagerSalaryFormScreen({
    super.key,
    this.managerSalaryId,
  });

  @override
  ConsumerState<ManagerSalaryFormScreen> createState() => _ManagerSalaryFormScreenState();
}

class _ManagerSalaryFormScreenState extends ConsumerState<ManagerSalaryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  final _salaryController = TextEditingController();

  bool _initialized = false;
  ManagerSalaryModel? _editingRecord;

  @override
  void dispose() {
    _salaryController.dispose();
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

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initialDate = isFrom ? _fromDate : _toDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _fromDate = _toDate;
          }
        }
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = _editingRecord != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingRecord!.createdDate : nowStr;
      final String createdT = isEdit ? _editingRecord!.createdTime : timeStr;

      final double weeklySalary = double.parse(_salaryController.text.trim());

      final record = ManagerSalaryModel(
        id: isEdit ? _editingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        fromDate: _formatDateString(_fromDate),
        toDate: _formatDateString(_toDate),
        weeklySalary: weeklySalary,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(managerSalaryListProvider.notifier).updateManagerSalary(record);
      } else {
        await ref.read(managerSalaryListProvider.notifier).addManagerSalary(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Manager Told Salary updated successfully' : 'Manager Told Salary saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(managerSalaryListProvider);
    final theme = Theme.of(context);

    if (widget.managerSalaryId != null && !_initialized && listAsync.hasValue) {
      final list = listAsync.value ?? [];
      final editRec = list.where((r) => r.id == widget.managerSalaryId).firstOrNull;
      if (editRec != null) {
        _editingRecord = editRec;
        _fromDate = DateTime.tryParse(editRec.fromDate) ?? _fromDate;
        _toDate = DateTime.tryParse(editRec.toDate) ?? _toDate;
        _salaryController.text = editRec.weeklySalary.toString();
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.managerSalaryId == null ? 'Add Manager Told Salary' : 'Edit Manager Told Salary'),
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
                  'Manager Told Salary Record',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // From Date
                const Text('From Date *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_formatDateString(_fromDate)),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // To Date
                const Text('To Date *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_formatDateString(_toDate)),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Weekly Salary Amount
                const Text('Weekly Salary Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _salaryController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5000.00',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Weekly salary amount is required';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null) {
                      return 'Please enter a valid number';
                    }
                    if (parsed <= 0) {
                      return 'Salary amount must be greater than zero';
                    }
                    return null;
                  },
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
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.managerSalaryId == null ? 'Save' : 'Save Changes'),
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
