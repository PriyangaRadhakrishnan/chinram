import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../models/worker_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/hive_attendance_repository.dart';
import '../services/attendance_service.dart';
import 'worker_provider.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return HiveAttendanceRepository();
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceService(repository);
});

// History provider to load all attendance logs
class AttendanceHistoryNotifier extends AsyncNotifier<List<AttendanceModel>> {
  late final AttendanceService _service;

  @override
  Future<List<AttendanceModel>> build() async {
    _service = ref.watch(attendanceServiceProvider);
    return _service.getAll();
  }

  Future<void> refreshHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getAll());
  }
}

final attendanceHistoryProvider = AsyncNotifierProvider<AttendanceHistoryNotifier, List<AttendanceModel>>(() {
  return AttendanceHistoryNotifier();
});

// UI helper model for editing/marking attendance
class WorkerAttendanceEditItem {
  final String workerId;
  final String name;
  final WorkerGender gender;
  final AttendanceStatus status;

  const WorkerAttendanceEditItem({
    required this.workerId,
    required this.name,
    required this.gender,
    required this.status,
  });

  WorkerAttendanceEditItem copyWith({
    String? workerId,
    String? name,
    WorkerGender? gender,
    AttendanceStatus? status,
  }) {
    return WorkerAttendanceEditItem(
      workerId: workerId ?? this.workerId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      status: status ?? this.status,
    );
  }
}

// State for active attendance marker screen
class ActiveAttendanceState {
  final DateTime selectedDate;
  final List<WorkerAttendanceEditItem> items;
  final bool isLoading;
  final bool hasAttendanceRecord;
  final bool isEditing;
  final String? createdDate;
  final String? createdTime;

  const ActiveAttendanceState({
    required this.selectedDate,
    required this.items,
    this.isLoading = false,
    this.hasAttendanceRecord = false,
    this.isEditing = true,
    this.createdDate,
    this.createdTime,
  });

  ActiveAttendanceState copyWith({
    DateTime? selectedDate,
    List<WorkerAttendanceEditItem>? items,
    bool? isLoading,
    bool? hasAttendanceRecord,
    bool? isEditing,
    String? createdDate,
    String? createdTime,
  }) {
    return ActiveAttendanceState(
      selectedDate: selectedDate ?? this.selectedDate,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasAttendanceRecord: hasAttendanceRecord ?? this.hasAttendanceRecord,
      isEditing: isEditing ?? this.isEditing,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
    );
  }
}

class ActiveAttendanceNotifier extends Notifier<ActiveAttendanceState> {
  @override
  ActiveAttendanceState build() {
    // Listen to workerListProvider changes to synchronize workers dynamically
    ref.listen<AsyncValue<List<WorkerModel>>>(workerListProvider, (previous, next) {
      if (next.hasValue) {
        _syncWorkersList(next.value!);
      }
    });

    Future.microtask(() => loadDate(DateTime.now()));
    return ActiveAttendanceState(
      selectedDate: DateTime.now(),
      items: const [],
      isLoading: true,
      isEditing: true,
    );
  }

  String _formatDateString(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    return _formatDateString(now);
  }

  String _getCurrentTimeString() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> loadDate(DateTime date) async {
    state = state.copyWith(isLoading: true, selectedDate: date);
    final dateStr = _formatDateString(date);

    final service = ref.read(attendanceServiceProvider);
    // Fetch saved record from service
    final record = await service.getByDate(dateStr);

    // Fetch workers list from WorkerProvider
    final workersAsync = ref.read(workerListProvider);
    final workers = workersAsync.value ?? [];

    // Worker Synchronization: Only Active workers should appear. Inactive/Deleted workers should not.
    final activeWorkers = workers.where((w) => w.status == WorkerStatus.active).toList();

    if (record != null) {
      // Create lookup map for saved records
      final Map<String, AttendanceStatus> savedStatusMap = {
        for (final rec in record.records) rec.workerId: rec.status
      };

      // Merge current active workers with saved statuses.
      // If a new worker was added after recording, they automatically appear as Present.
      // Deleted workers disappear automatically since they are not in activeWorkers.
      final editItems = activeWorkers.map((w) {
        final savedStatus = savedStatusMap[w.id];
        return WorkerAttendanceEditItem(
          workerId: w.id,
          name: w.name ?? 'Unknown Worker',
          gender: w.gender,
          status: savedStatus ?? AttendanceStatus.present,
        );
      }).toList();

      state = state.copyWith(
        items: editItems,
        isLoading: false,
        hasAttendanceRecord: true,
        isEditing: false, // Default to read-only when record exists
        createdDate: record.createdDate,
        createdTime: record.createdTime,
      );
    } else {
      // Create new list of active workers with default status Present
      final editItems = activeWorkers.map((w) {
        return WorkerAttendanceEditItem(
          workerId: w.id,
          name: w.name ?? 'Unknown Worker',
          gender: w.gender,
          status: AttendanceStatus.present,
        );
      }).toList();

      state = state.copyWith(
        items: editItems,
        isLoading: false,
        hasAttendanceRecord: false,
        isEditing: true, // Default to edit mode when no record exists
        createdDate: _getCurrentDateString(),
        createdTime: _getCurrentTimeString(),
      );
    }
  }

  void _syncWorkersList(List<WorkerModel> currentWorkers) {
    // Only Active workers should appear
    final activeWorkers = currentWorkers.where((w) => w.status == WorkerStatus.active).toList();
    
    // Map current marking/editing status of workers to preserve unsaved choices
    final Map<String, AttendanceStatus> currentStatusMap = {
      for (final item in state.items) item.workerId: item.status
    };

    final mergedItems = activeWorkers.map((w) {
      final status = currentStatusMap[w.id] ?? AttendanceStatus.present;
      return WorkerAttendanceEditItem(
        workerId: w.id,
        name: w.name ?? 'Unknown Worker',
        gender: w.gender,
        status: status,
      );
    }).toList();

    state = state.copyWith(items: mergedItems);
  }

  void enableEditing() {
    state = state.copyWith(isEditing: true);
  }

  void updateStatus(String workerId, AttendanceStatus status) {
    if (!state.isEditing) return; // Prevent status updates if not in edit mode
    
    final updatedItems = state.items.map((item) {
      if (item.workerId == workerId) {
        return item.copyWith(status: status);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  Future<void> saveAttendance() async {
    state = state.copyWith(isLoading: true);
    final dateStr = _formatDateString(state.selectedDate);

    // Set timestamps
    final String cDate = state.createdDate ?? _getCurrentDateString();
    final String cTime = state.createdTime ?? _getCurrentTimeString();
    final String uDate = _getCurrentDateString();
    final String uTime = _getCurrentTimeString();

    final model = AttendanceModel(
      date: dateStr,
      records: state.items.map((item) {
        return WorkerAttendanceModel(
          workerId: item.workerId,
          status: item.status,
        );
      }).toList(),
      createdDate: cDate,
      createdTime: cTime,
      lastUpdatedDate: uDate,
      lastUpdatedTime: uTime,
    );

    final service = ref.read(attendanceServiceProvider);
    await service.save(model);
    
    // Refresh history
    await ref.read(attendanceHistoryProvider.notifier).refreshHistory();

    state = state.copyWith(
      isLoading: false,
      hasAttendanceRecord: true,
      isEditing: false, // Go back to read-only after saving
      createdDate: cDate,
      createdTime: cTime,
    );
  }

  Future<void> deleteAttendance() async {
    state = state.copyWith(isLoading: true);
    final dateStr = _formatDateString(state.selectedDate);

    final service = ref.read(attendanceServiceProvider);
    await service.delete(dateStr);

    // Refresh history
    await ref.read(attendanceHistoryProvider.notifier).refreshHistory();

    // Reload active worker defaults for this date
    await loadDate(state.selectedDate);
  }
}

final activeAttendanceProvider =
    NotifierProvider<ActiveAttendanceNotifier, ActiveAttendanceState>(() {
  return ActiveAttendanceNotifier();
});
