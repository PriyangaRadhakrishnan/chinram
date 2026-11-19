import '../models/manager_salary_model.dart';

abstract class ManagerSalaryRepository {
  Future<List<ManagerSalaryModel>> getAll();
  Future<ManagerSalaryModel?> getById(String id);
  Future<void> save(ManagerSalaryModel record);
  Future<void> delete(String id);
}
