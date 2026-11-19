import '../models/farm_income_model.dart';

abstract class FarmIncomeRepository {
  Future<List<FarmIncomeModel>> getAll();
  Future<FarmIncomeModel?> getById(String id);
  Future<void> add(FarmIncomeModel income);
  Future<void> update(FarmIncomeModel income);
  Future<void> delete(String id);
}
