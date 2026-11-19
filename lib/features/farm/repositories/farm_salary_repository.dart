import '../models/farm_salary_model.dart';

abstract class FarmSalaryRepository {
  Future<List<FarmSalaryModel>> getAll();
  Future<FarmSalaryModel?> getById(String id);
  Future<void> add(FarmSalaryModel salary);
  Future<void> update(FarmSalaryModel salary);
  Future<void> delete(String id);
}
