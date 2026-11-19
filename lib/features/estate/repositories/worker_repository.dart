import '../models/worker_model.dart';

abstract class WorkerRepository {
  Future<List<WorkerModel>> getAll();
  Future<WorkerModel?> getById(String id);
  Future<void> add(WorkerModel worker);
  Future<void> update(WorkerModel worker);
  Future<void> delete(String id);
}
