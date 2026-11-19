import '../models/worker_model.dart';
import 'worker_repository.dart';

class MockWorkerRepository implements WorkerRepository {
  static final List<WorkerModel> _defaultRecords = [
    const WorkerModel(
      id: '1',
      name: 'Ramesh Kumar',
      gender: WorkerGender.male,
      phoneNumber: '9876543210',
      status: WorkerStatus.active,
      notes: 'Senior rubber tapper. Very reliable.',
    ),
    const WorkerModel(
      id: '2',
      name: 'Priyanga Radhakrishnan',
      gender: WorkerGender.female,
      phoneNumber: '9876543211',
      status: WorkerStatus.active,
      notes: 'Dryer supervisor. Manages drying schedules.',
    ),
    const WorkerModel(
      id: '3',
      name: 'Suresh Raina',
      gender: WorkerGender.male,
      phoneNumber: '9876543212',
      status: WorkerStatus.inactive,
      notes: 'Inactive due to medical leave.',
    ),
    const WorkerModel(
      id: '4',
      name: 'Anjali Sharma',
      gender: WorkerGender.female,
      phoneNumber: '9876543213',
      status: WorkerStatus.active,
      notes: 'Tapper. Focuses on Sector B.',
    ),
    const WorkerModel(
      id: '5',
      name: 'Vijay Joseph',
      gender: WorkerGender.male,
      phoneNumber: null,
      status: WorkerStatus.active,
      notes: 'Temporary worker.',
    ),
  ];

  static List<WorkerModel> _records = List.from(_defaultRecords);

  static void reset() {
    _records = List.from(_defaultRecords);
  }

  MockWorkerRepository();

  @override
  Future<List<WorkerModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_records);
  }

  @override
  Future<WorkerModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _records.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(WorkerModel worker) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _records.add(worker);
  }

  @override
  Future<void> update(WorkerModel worker) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _records.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _records[index] = worker;
    }
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _records.removeWhere((w) => w.id == id);
  }
}
