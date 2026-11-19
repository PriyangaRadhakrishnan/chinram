import '../models/salary_model.dart';
import '../models/salary_configuration_model.dart';

abstract class SalaryRepository {
  Future<List<SalaryModel>> getAll();
  Future<SalaryModel?> getById(String id);
  Future<void> save(SalaryModel salary);
  Future<void> delete(String id);

  Future<SalaryConfigurationModel> getConfiguration();
  Future<void> saveConfiguration(SalaryConfigurationModel config);
}
