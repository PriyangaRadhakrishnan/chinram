import '../models/farm_salary_model.dart';
import '../repositories/farm_salary_repository.dart';

class FarmSalaryService {
  final FarmSalaryRepository _repository;

  const FarmSalaryService(this._repository);

  Future<List<FarmSalaryModel>> getAll() => _repository.getAll();
  Future<FarmSalaryModel?> getById(String id) => _repository.getById(id);
  Future<void> add(FarmSalaryModel salary) => _repository.add(salary);
  Future<void> update(FarmSalaryModel salary) => _repository.update(salary);
  Future<void> delete(String id) => _repository.delete(id);
}
