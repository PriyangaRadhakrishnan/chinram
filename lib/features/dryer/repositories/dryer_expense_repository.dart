import '../models/dryer_expense_model.dart';

abstract class DryerExpenseRepository {
  Future<List<DryerExpense>> getAll();
  Future<DryerExpense?> getById(String id);
  Future<void> add(DryerExpense expense);
  Future<void> update(DryerExpense expense);
  Future<void> delete(String id);
}
