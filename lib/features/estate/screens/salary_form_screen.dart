import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/salary_model.dart';
import '../models/worker_model.dart';
import '../models/attendance_model.dart';
import '../providers/salary_provider.dart';
import '../providers/worker_provider.dart';
import '../providers/attendance_provider.dart';

class SalaryFormScreen extends ConsumerStatefulWidget {
  final String? salaryId;

  const SalaryFormScreen({
    super.key,
    this.salaryId,
  });

  @override
  ConsumerState<SalaryFormScreen> createState() => _SalaryFormScreenState();
}

class _SalaryFormScreenState extends ConsumerState<SalaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String? _selectedWorkerId;
  String _periodName = '';
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  
  String _calculationMethod = 'attendance'; // 'attendance' | 'manual'
  String _durationUnit = 'days'; // 'days' | 'weeks' | 'months'
  final _manualValueController = TextEditingController(text: '1');
  
  String _paymentStatus = 'pending';

  bool _initialized = false;
  SalaryModel? _editingSalary;

  @override
  void dispose() {
    _manualValueController.dispose();
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  int _calculatePresentDays(List<AttendanceModel> history, String workerId) {
    int count = 0;
    final normStart = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final normEnd = DateTime(_endDate.year, _endDate.month, _endDate.day);

    for (final sheet in history) {
      try {
        final date = DateTime.parse(sheet.date);
        final normDate = DateTime(date.year, date.month, date.day);
        if (normDate.compareTo(normStart) >= 0 && normDate.compareTo(normEnd) <= 0) {
          final rec = sheet.records.firstWhere(
            (r) => r.workerId == workerId,
            orElse: () => const WorkerAttendanceModel(workerId: '', status: AttendanceStatus.absent),
          );
          if (rec.workerId.isNotEmpty && rec.status == AttendanceStatus.present) {
            count++;
          }
        }
      } catch (_) {}
    }
    return count;
  }

  void _save(
    double dailyWage,
    int presentDays,
    double totalSalary,
  ) async {
    if (_formKey.currentState!.validate()) {
      final isEdit = _editingSalary != null;
      final String nowStr = _formatDateString(DateTime.now());
      final String timeStr = _getCurrentTimeString();

      final String createdD = isEdit ? _editingSalary!.createdDate : nowStr;
      final String createdT = isEdit ? _editingSalary!.createdTime : timeStr;

      // Log payment timestamps if marked Paid
      final String? payD = _paymentStatus == 'paid'
          ? (isEdit && _editingSalary!.paymentStatus == 'paid' ? _editingSalary!.paymentDate : nowStr)
          : null;
      final String? payT = _paymentStatus == 'paid'
          ? (isEdit && _editingSalary!.paymentStatus == 'paid' ? _editingSalary!.paymentTime : timeStr)
          : null;

      final salary = SalaryModel(
        id: isEdit ? _editingSalary!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        workerId: _selectedWorkerId!,
        period: _periodName.trim(),
        startDate: _formatDateString(_startDate),
        endDate: _formatDateString(_endDate),
        calculationMethod: _calculationMethod,
        durationUnit: _durationUnit,
        durationValue: int.tryParse(_manualValueController.text) ?? 0,
        presentDays: presentDays,
        dailyWage: dailyWage,
        totalSalary: totalSalary,
        paymentStatus: _paymentStatus,
        paymentDate: payD,
        paymentTime: payT,
        createdDate: createdD,
        createdTime: createdT,
        lastUpdatedDate: nowStr,
        lastUpdatedTime: timeStr,
      );

      if (isEdit) {
        await ref.read(salaryListProvider.notifier).updateSalary(salary);
      } else {
        await ref.read(salaryListProvider.notifier).addSalary(salary);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Salary updated successfully' : 'Salary generated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workerListProvider);
    final attendanceAsync = ref.watch(attendanceHistoryProvider);
    final configAsync = ref.watch(salaryConfigProvider);
    final salaryListAsync = ref.watch(salaryListProvider);

    final theme = Theme.of(context);

    // Load initial edit data if editing
    if (widget.salaryId != null && !_initialized && salaryListAsync.hasValue) {
      final list = salaryListAsync.value ?? [];
      final editSalary = list.where((s) => s.id == widget.salaryId).firstOrNull;
      if (editSalary != null) {
        _editingSalary = editSalary;
        _selectedWorkerId = editSalary.workerId;
        _periodName = editSalary.period;
        _startDate = DateTime.tryParse(editSalary.startDate) ?? _startDate;
        _endDate = DateTime.tryParse(editSalary.endDate) ?? _endDate;
        _calculationMethod = editSalary.calculationMethod;
        _durationUnit = editSalary.durationUnit;
        _manualValueController.text = editSalary.durationValue.toString();
        _paymentStatus = editSalary.paymentStatus;
        _initialized = true;
      }
    }

    if (_periodName.isEmpty && !_initialized) {
      // Setup default period name based on current date
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      _periodName = '${months[now.month - 1]} ${now.year}';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salaryId == null ? 'Generate Salary' : 'Edit Salary'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: workersAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading workers...'),
          error: (err, stack) => Center(child: Text('Error loading workers: $err')),
          data: (workersList) {
            // Dropdown list must only contain active workers, or if editing, also include the editing worker in case they became inactive.
            final displayWorkers = workersList.where((w) {
              if (w.status == WorkerStatus.active) return true;
              if (widget.salaryId != null && w.id == _selectedWorkerId) return true;
              return false;
            }).toList();

            if (displayWorkers.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline,
                title: 'No Workers Available',
                description: 'Ensure active workers are registered in Worker Management first.',
              );
            }

            // Set initial selected worker if none selected
            _selectedWorkerId ??= displayWorkers.first.id;

            final selectedWorker = displayWorkers.firstWhere(
              (w) => w.id == _selectedWorkerId,
              orElse: () => displayWorkers.first,
            );

            return configAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading base wages...'),
              error: (err, stack) => Center(child: Text('Error loading wages config: $err')),
              data: (config) {
                // Determine Daily Wage
                final dailyWage = selectedWorker.gender == WorkerGender.male
                    ? config.maleDailyWage
                    : config.femaleDailyWage;

                // Calculate worked duration & total salary based on method
                int presentDays = 0;
                double totalSalary = 0.0;
                String workedDurationString = '';

                if (_calculationMethod == 'attendance') {
                  final attendanceHistory = attendanceAsync.value ?? [];
                  presentDays = _calculatePresentDays(attendanceHistory, selectedWorker.id);
                  totalSalary = presentDays * dailyWage;
                  workedDurationString = '$presentDays Days';
                } else {
                  final val = int.tryParse(_manualValueController.text) ?? 0;
                  if (_durationUnit == 'days') {
                    totalSalary = val * dailyWage;
                    workedDurationString = '$val Days';
                  } else if (_durationUnit == 'weeks') {
                    totalSalary = val * 7 * dailyWage;
                    workedDurationString = '$val Weeks';
                  } else if (_durationUnit == 'months') {
                    totalSalary = val * 30 * dailyWage;
                    workedDurationString = '$val Months';
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Worker Selection
                        Text(
                          'Worker Selection',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _selectedWorkerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: displayWorkers.map((w) {
                            return DropdownMenuItem(
                              value: w.id,
                              child: Text('${w.name ?? 'Unknown'} (${w.gender.label})'),
                            );
                          }).toList(),
                          onChanged: widget.salaryId != null
                              ? null // Disable changing worker in edit mode
                              : (val) {
                                  setState(() {
                                    _selectedWorkerId = val;
                                  });
                                },
                        ),
                        const SizedBox(height: 24),

                        // Period Details
                        Text(
                          'Salary Period & Dates',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _periodName,
                          decoration: const InputDecoration(
                            hintText: 'e.g. July 2026',
                            prefixIcon: Icon(Icons.calendar_view_month),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please enter a period name';
                            return null;
                          },
                          onChanged: (val) => _periodName = val,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    onPressed: () => _selectDate(context, true),
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(_formatDateString(_startDate)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    onPressed: () => _selectDate(context, false),
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(_formatDateString(_endDate)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Calculation Mode
                        Text(
                          'Calculation Method',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Automatic (Attendance)')),
                                selected: _calculationMethod == 'attendance',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _calculationMethod = 'attendance';
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Manual Input')),
                                selected: _calculationMethod == 'manual',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _calculationMethod = 'manual';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Manual configuration fields
                        if (_calculationMethod == 'manual') ...[
                          Text(
                            'Worked Duration',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  // ignore: deprecated_member_use
                                  value: _durationUnit,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'days', child: Text('Days')),
                                    DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                                    DropdownMenuItem(value: 'months', child: Text('Months')),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _durationUnit = val!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _manualValueController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Duration count',
                                    prefixIcon: Icon(Icons.av_timer),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Enter duration';
                                    if (int.tryParse(val) == null) return 'Enter a whole number';
                                    if (int.parse(val) <= 0) return 'Must be greater than 0';
                                    return null;
                                  },
                                  onChanged: (_) {
                                    setState(() {}); // Trigger salary live update
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Payment Status dropdown
                        Text(
                          'Payment Status',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _paymentStatus,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'paid', child: Text('Paid')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _paymentStatus = val!;
                            });
                          },
                        ),
                        const SizedBox(height: 32),

                        // Live Preview Summary Card
                        Card(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salary Preview Summary',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Divider(height: 24),
                                _SummaryRow(label: 'Worker Name', value: selectedWorker.name ?? 'Unknown'),
                                _SummaryRow(label: 'Gender', value: selectedWorker.gender.label),
                                _SummaryRow(
                                  label: 'Method',
                                  value: _calculationMethod == 'attendance' ? 'Automatic (Attendance)' : 'Manual',
                                ),
                                _SummaryRow(label: 'Worked Duration', value: workedDurationString),
                                if (_calculationMethod == 'attendance')
                                  _SummaryRow(label: 'Present Days', value: presentDays.toString()),
                                _SummaryRow(label: 'Applied Daily Wage', value: '₹${dailyWage.toStringAsFixed(2)}'),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Calculated Salary',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '₹${totalSalary.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save actions
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
                                onPressed: () => _save(dailyWage, presentDays, totalSalary),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 50),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(widget.salaryId == null ? 'Generate Salary' : 'Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
