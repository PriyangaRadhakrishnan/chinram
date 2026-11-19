import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/worker_model.dart';
import '../providers/worker_provider.dart';

class WorkerFormScreen extends ConsumerStatefulWidget {
  final String? workerId;

  const WorkerFormScreen({super.key, this.workerId});

  @override
  ConsumerState<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends ConsumerState<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  WorkerGender? _selectedGender;
  WorkerStatus? _selectedStatus; // Defaults to null, which resolves to Active

  bool get _isEdit => widget.workerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkerData());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadWorkerData() async {
    final service = ref.read(workerServiceProvider);
    final record = await service.getById(widget.workerId!);
    if (record != null && mounted) {
      setState(() {
        _nameController.text = record.name ?? '';
        _phoneController.text = record.phoneNumber ?? '';
        _notesController.text = record.notes ?? '';
        _selectedGender = record.gender;
        _selectedStatus = record.status;
      });
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select gender'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final worker = WorkerModel(
        id: widget.workerId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        gender: _selectedGender!,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        status: _selectedStatus ?? WorkerStatus.active, // default Active if empty/null
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final notifier = ref.read(workerListProvider.notifier);
      if (_isEdit) {
        await notifier.updateWorker(worker);
      } else {
        await notifier.addWorker(worker);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Worker updated successfully' : 'Worker added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Worker' : 'Add Worker'),
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
                // Worker Name Field (Optional)
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Worker Name',
                  hintText: 'Enter name (optional)',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 20),

                // Gender Select Field (Mandatory)
                DropdownButtonFormField<WorkerGender>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: WorkerGender.values.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGender = val;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Number Field (Optional)
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: 'Enter 10-digit number (optional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Status Field (Optional, Defaults to Active)
                DropdownButtonFormField<WorkerStatus>(
                  initialValue: _selectedStatus ?? WorkerStatus.active,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items: WorkerStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Notes Field (Optional, Multi-line Material 3 field)
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Enter additional notes (optional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  text: _isEdit ? 'Update Worker' : 'Add Worker',
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
