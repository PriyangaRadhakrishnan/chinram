import '../models/weekly_expense_model.dart';

abstract class WeeklyExpenseRepository {
  Future<List<WeeklyExpenseModel>> getAll();
  Future<WeeklyExpenseModel?> getById(String id);
  Future<void> save(WeeklyExpenseModel expense);
  Future<void> delete(String id);
}
