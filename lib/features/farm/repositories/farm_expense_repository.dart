import '../models/farm_expense_model.dart';

abstract class FarmExpenseRepository {
  Future<List<FarmExpenseModel>> getAll();
  Future<FarmExpenseModel?> getById(String id);
  Future<void> add(FarmExpenseModel expense);
  Future<void> update(FarmExpenseModel expense);
  Future<void> delete(String id);
}
