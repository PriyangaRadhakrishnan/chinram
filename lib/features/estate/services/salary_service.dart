import '../models/salary_model.dart';
import '../models/salary_configuration_model.dart';
import '../repositories/salary_repository.dart';

class SalaryService {
  final SalaryRepository _repository;

  const SalaryService(this._repository);

  Future<List<SalaryModel>> getAll() => _repository.getAll();
  Future<SalaryModel?> getById(String id) => _repository.getById(id);
  Future<void> save(SalaryModel salary) => _repository.save(salary);
  Future<void> delete(String id) => _repository.delete(id);

  Future<SalaryConfigurationModel> getConfiguration() => _repository.getConfiguration();
  Future<void> saveConfiguration(SalaryConfigurationModel config) => _repository.saveConfiguration(config);
}
