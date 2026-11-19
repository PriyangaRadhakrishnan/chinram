import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_salary_model.dart';
import '../providers/farm_salary_provider.dart';

class FarmSalaryFormScreen extends ConsumerStatefulWidget {
  final String? salaryId;

  const FarmSalaryFormScreen({
    super.key,
    this.salaryId,
  });

  @override
  ConsumerState<FarmSalaryFormScreen> createState() => _FarmSalaryFormScreenState();
}

class _FarmSalaryFormScreenState extends ConsumerState<FarmSalaryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  final _workController = TextEditingController();
  final _personsController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();

  bool _initialized = false;
  FarmSalaryModel? _editingRecord;

  @override
  void dispose() {
    _workController.dispose();
    _personsController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateString(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
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
      final String nowStr = _getCurrentDateString();
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingRecord!.createdDate : nowStr;
      final String createdT = isEdit ? _editingRecord!.createdTime : timeStr;

      final int persons = int.parse(_personsController.text.trim());
      final double salary = double.parse(_salaryController.text.trim());

      final record = FarmSalaryModel(
        id: isEdit ? _editingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        fromDate: _fromDate,
        toDate: _toDate,
        work: _workController.text.trim(),
        numberOfPersons: persons,
        salaryAmount: salary,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(farmSalaryListProvider.notifier).updateSalary(record);
      } else {
        await ref.read(farmSalaryListProvider.notifier).addSalary(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Farm Salary updated successfully' : 'Farm Salary saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(farmSalaryListProvider);
    final theme = Theme.of(context);

    if (widget.salaryId != null && !_initialized && listAsync.hasValue) {
      final list = listAsync.value ?? [];
      final editRec = list.where((r) => r.id == widget.salaryId).firstOrNull;
      if (editRec != null) {
        _editingRecord = editRec;
        _fromDate = editRec.fromDate;
        _toDate = editRec.toDate;
        _workController.text = editRec.work;
        _personsController.text = editRec.numberOfPersons.toString();
        _salaryController.text = editRec.salaryAmount.toString();
        _notesController.text = editRec.notes ?? '';
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salaryId == null ? 'Add Farm Salary' : 'Edit Farm Salary'),
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
                  'Farm Salary Record',
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

                // Work Description
                const Text('Work Done *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _workController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Harvesting, Weeding, Spraying',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the work details';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Number of Persons
                const Text('Number of Persons *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _personsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter person count';
                    }
                    final count = int.tryParse(val.trim());
                    if (count == null || count <= 0) {
                      return 'Enter a positive whole number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Salary Amount
                const Text('Salary Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _salaryController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 7500.00',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the salary amount';
                    }
                    final amount = double.tryParse(val.trim());
                    if (amount == null || amount < 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Notes
                const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Any specific details, worker names, etc.',
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
