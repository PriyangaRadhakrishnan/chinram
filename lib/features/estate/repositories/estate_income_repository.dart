import '../models/estate_income_model.dart';

abstract class EstateIncomeRepository {
  Future<List<EstateIncomeModel>> getAll();
  Future<EstateIncomeModel?> getById(String id);
  Future<void> add(EstateIncomeModel income);
  Future<void> update(EstateIncomeModel income);
  Future<void> delete(String id);
}
