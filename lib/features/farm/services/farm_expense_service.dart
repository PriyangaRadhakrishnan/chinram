import '../models/farm_expense_model.dart';
import '../repositories/farm_expense_repository.dart';

class FarmExpenseService {
  final FarmExpenseRepository _repository;

  const FarmExpenseService(this._repository);

  Future<List<FarmExpenseModel>> getAll() => _repository.getAll();
  Future<FarmExpenseModel?> getById(String id) => _repository.getById(id);
  Future<void> add(FarmExpenseModel expense) => _repository.add(expense);
  Future<void> update(FarmExpenseModel expense) => _repository.update(expense);
  Future<void> delete(String id) => _repository.delete(id);
}
