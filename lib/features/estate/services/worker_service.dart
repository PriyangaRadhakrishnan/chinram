import '../models/worker_model.dart';
import '../repositories/worker_repository.dart';

class WorkerService {
  final WorkerRepository _repository;

  const WorkerService(this._repository);

  Future<List<WorkerModel>> getAll() => _repository.getAll();
  Future<WorkerModel?> getById(String id) => _repository.getById(id);
  Future<void> add(WorkerModel worker) => _repository.add(worker);
  Future<void> update(WorkerModel worker) => _repository.update(worker);
  Future<void> delete(String id) => _repository.delete(id);
}
