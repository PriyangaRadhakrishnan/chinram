import '../models/estate_income_model.dart';
import '../repositories/estate_income_repository.dart';

class EstateIncomeService {
  final EstateIncomeRepository _repository;

  const EstateIncomeService(this._repository);

  Future<List<EstateIncomeModel>> getAll() => _repository.getAll();
  Future<EstateIncomeModel?> getById(String id) => _repository.getById(id);
  Future<void> add(EstateIncomeModel income) => _repository.add(income);
  Future<void> update(EstateIncomeModel income) => _repository.update(income);
  Future<void> delete(String id) => _repository.delete(id);
}
