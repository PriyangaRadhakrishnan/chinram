import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../repositories/worker_repository.dart';
import '../repositories/hive_worker_repository.dart';
import '../services/worker_service.dart';

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return HiveWorkerRepository();
});

final workerServiceProvider = Provider<WorkerService>((ref) {
  final repository = ref.watch(workerRepositoryProvider);
  return WorkerService(repository);
});

class WorkerListNotifier extends AsyncNotifier<List<WorkerModel>> {
  late final WorkerService _service;

  @override
  Future<List<WorkerModel>> build() async {
    _service = ref.watch(workerServiceProvider);
    return _service.getAll();
  }

  Future<void> addWorker(WorkerModel worker) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.add(worker);
      return _service.getAll();
    });
  }

  Future<void> updateWorker(WorkerModel worker) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.update(worker);
      return _service.getAll();
    });
  }

  Future<void> deleteWorker(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final workerListProvider = AsyncNotifierProvider<WorkerListNotifier, List<WorkerModel>>(() {
  return WorkerListNotifier();
});
