import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/tree_count_model.dart';
import '../providers/tree_count_provider.dart';

class TreeCountFormScreen extends ConsumerStatefulWidget {
  final String? treeCountId;

  const TreeCountFormScreen({
    super.key,
    this.treeCountId,
  });

  @override
  ConsumerState<TreeCountFormScreen> createState() => _TreeCountFormScreenState();
}

class _TreeCountFormScreenState extends ConsumerState<TreeCountFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & fields
  DateTime _selectedDate = DateTime.now();
  final _treeNameController = TextEditingController();
  String? _selectedPlot;
  final _countController = TextEditingController();

  bool _initialized = false;
  TreeCountModel? _editingRecord;

  @override
  void dispose() {
    _treeNameController.dispose();
    _countController.dispose();
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
      final isEdit = _editingRecord != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingRecord!.createdDate : nowStr;
      final String createdT = isEdit ? _editingRecord!.createdTime : timeStr;

      final countVal = int.tryParse(_countController.text) ?? 0;

      final record = TreeCountModel(
        id: isEdit ? _editingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        date: _formatDateString(_selectedDate),
        treeName: _treeNameController.text.trim(),
        plotName: _selectedPlot!,
        initialCount: countVal,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(treeCountListProvider.notifier).updateTreeCount(record, countVal);
      } else {
        await ref.read(treeCountListProvider.notifier).addTreeCount(record, countVal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Tree count record updated successfully' : 'Tree count record added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(treeCountListProvider);
    final theme = Theme.of(context);

    // Populate edit data
    if (widget.treeCountId != null && !_initialized && listAsync.hasValue) {
      final list = listAsync.value ?? [];
      final editRec = list.where((r) => r.id == widget.treeCountId).firstOrNull;
      if (editRec != null) {
        _editingRecord = editRec;
        _selectedDate = DateTime.tryParse(editRec.date) ?? _selectedDate;
        _treeNameController.text = editRec.treeName;
        _selectedPlot = editRec.plotName;
        _countController.text = editRec.initialCount.toString();
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.treeCountId == null ? 'Add Tree Count' : 'Edit Tree Count'),
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
                  'Record Details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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

                // Tree Name
                const Text('Tree Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _treeNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Coffee, Cardamom',
                    prefixIcon: Icon(Icons.nature),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter tree name';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Plot Dropdown
                const Text('Plot *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedPlot,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  hint: const Text('Select a plot'),
                  items: const [
                    DropdownMenuItem(value: 'Plot A', child: Text('Plot A')),
                    DropdownMenuItem(value: 'Plot B', child: Text('Plot B')),
                    DropdownMenuItem(value: 'Plot C', child: Text('Plot C')),
                    DropdownMenuItem(value: 'Plot D', child: Text('Plot D')),
                  ],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please select a plot';
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _selectedPlot = val;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Number of Trees
                const Text('Number of Trees *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 350',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter number of trees';
                    if (int.tryParse(val) == null) return 'Enter a valid number';
                    if (int.parse(val) <= 0) return 'Must be greater than zero';
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
                        child: Text(widget.treeCountId == null ? 'Add Record' : 'Save Changes'),
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
