import '../models/weekly_expense_model.dart';
import '../repositories/weekly_expense_repository.dart';

class WeeklyExpenseService {
  final WeeklyExpenseRepository _repository;

  const WeeklyExpenseService(this._repository);

  Future<List<WeeklyExpenseModel>> getAll() => _repository.getAll();
  Future<WeeklyExpenseModel?> getById(String id) => _repository.getById(id);
  Future<void> save(WeeklyExpenseModel expense) => _repository.save(expense);
  Future<void> delete(String id) => _repository.delete(id);
}
