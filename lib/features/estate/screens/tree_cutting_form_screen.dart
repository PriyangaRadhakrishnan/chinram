import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/tree_cutting_model.dart';
import '../providers/tree_cutting_provider.dart';

class TreeCuttingFormScreen extends ConsumerStatefulWidget {
  final String? treeCuttingId;

  const TreeCuttingFormScreen({
    super.key,
    this.treeCuttingId,
  });

  @override
  ConsumerState<TreeCuttingFormScreen> createState() => _TreeCuttingFormScreenState();
}

class _TreeCuttingFormScreenState extends ConsumerState<TreeCuttingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime _selectedDate = DateTime.now();
  final _treeNameController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _countController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalPriceController = TextEditingController();

  String _treeCountOption = 'Nil';
  double _totalAmount = 0.0;
  bool _initialized = false;
  TreeCuttingModel? _editingRecord;

  @override
  void initState() {
    super.initState();
    _countController.addListener(_onCountChanged);
    _priceController.addListener(_onPriceChanged);
  }

  @override
  void dispose() {
    _countController.removeListener(_onCountChanged);
    _priceController.removeListener(_onPriceChanged);
    _treeNameController.dispose();
    _placeNameController.dispose();
    _countController.dispose();
    _priceController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  void _onCountChanged() {
    final count = int.tryParse(_countController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalAmount = count * price;
    });
  }

  void _onPriceChanged() {
    final count = int.tryParse(_countController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalAmount = count * price;
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

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = _editingRecord != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingRecord!.createdDate : nowStr;
      final String createdT = isEdit ? _editingRecord!.createdTime : timeStr;

      final bool hasCount = _treeCountOption == 'Enter Quantity';
      final int? countVal = hasCount ? int.tryParse(_countController.text) : null;
      final double? priceVal = hasCount ? (double.tryParse(_priceController.text) ?? 0.0) : null;
      final double finalTotal = hasCount 
          ? ((countVal ?? 0) * (priceVal ?? 0.0)) 
          : (double.tryParse(_totalPriceController.text) ?? 0.0);

      final record = TreeCuttingModel(
        id: isEdit ? _editingRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        date: _formatDateString(_selectedDate),
        treeName: _treeNameController.text.trim().isEmpty ? null : _treeNameController.text.trim(),
        placeName: _placeNameController.text.trim().isEmpty ? null : _placeNameController.text.trim(),
        numberOfTrees: countVal,
        pricePerTree: priceVal,
        totalAmount: finalTotal,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(treeCuttingListProvider.notifier).updateTreeCutting(record);
      } else {
        await ref.read(treeCuttingListProvider.notifier).addTreeCutting(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Cutting log updated successfully' : 'Cutting log saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuttingListAsync = ref.watch(treeCuttingListProvider);
    final theme = Theme.of(context);

    // Populate edit data
    if (widget.treeCuttingId != null && !_initialized && cuttingListAsync.hasValue) {
      final list = cuttingListAsync.value ?? [];
      final editRec = list.where((c) => c.id == widget.treeCuttingId).firstOrNull;
      if (editRec != null) {
        _editingRecord = editRec;
        _selectedDate = DateTime.tryParse(editRec.date) ?? _selectedDate;
        _treeNameController.text = editRec.treeName ?? '';
        _placeNameController.text = editRec.placeName ?? '';
        if (editRec.numberOfTrees != null) {
          _treeCountOption = 'Enter Quantity';
          _countController.text = editRec.numberOfTrees.toString();
          _priceController.text = editRec.pricePerTree?.toString() ?? '';
        } else {
          _treeCountOption = 'Nil';
          _totalPriceController.text = editRec.totalAmount.toString();
        }
        _totalAmount = editRec.totalAmount;
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.treeCuttingId == null ? 'Log Tree Cutting' : 'Edit Tree Cutting'),
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
                  'Log Tree Cutting',
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
                const Text('Tree Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _treeNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Teak, Rosewood',
                    prefixIcon: Icon(Icons.nature),
                  ),
                ),
                const SizedBox(height: 20),

                // Place Name
                const Text('Place Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _placeNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Area A, West Boundary',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 20),

                // Tree Count Dropdown
                const Text('Tree Count *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _treeCountOption,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Nil', child: Text('Nil')),
                    DropdownMenuItem(value: 'Enter Quantity', child: Text('Enter Quantity')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _treeCountOption = val;
                        if (_treeCountOption == 'Nil') {
                          _countController.clear();
                          _priceController.clear();
                          _totalAmount = 0.0;
                        } else {
                          _totalPriceController.clear();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                if (_treeCountOption == 'Enter Quantity') ...[
                  // Number of Trees Cut
                  const Text('Number of Trees Cut *', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 10',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter trees count';
                      final parsed = int.tryParse(val);
                      if (parsed == null) return 'Enter a whole number';
                      if (parsed <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Price Per Tree
                  const Text('Price Per Tree (₹) *', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 2000.00',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter price per tree';
                      final parsed = double.tryParse(val);
                      if (parsed == null) return 'Invalid price';
                      if (parsed <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Auto-calculated total amount card
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount (Calculated)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '₹${_totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Total Price (Manual input)
                  const Text('Total Price (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _totalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 15000.00',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final parsed = double.tryParse(val);
                        if (parsed == null) return 'Invalid price';
                        if (parsed <= 0) return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ],
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
                        child: Text(widget.treeCuttingId == null ? 'Log Cutting' : 'Save Changes'),
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
