import '../models/manager_salary_model.dart';
import '../repositories/manager_salary_repository.dart';

class ManagerSalaryService {
  final ManagerSalaryRepository _repository;

  const ManagerSalaryService(this._repository);

  Future<List<ManagerSalaryModel>> getAll() => _repository.getAll();
  Future<ManagerSalaryModel?> getById(String id) => _repository.getById(id);
  Future<void> save(ManagerSalaryModel record) => _repository.save(record);
  Future<void> delete(String id) => _repository.delete(id);
}
