import '../models/farm_income_model.dart';
import '../repositories/farm_income_repository.dart';

class FarmIncomeService {
  final FarmIncomeRepository _repository;

  const FarmIncomeService(this._repository);

  Future<List<FarmIncomeModel>> getAll() => _repository.getAll();
  Future<FarmIncomeModel?> getById(String id) => _repository.getById(id);
  Future<void> add(FarmIncomeModel income) => _repository.add(income);
  Future<void> update(FarmIncomeModel income) => _repository.update(income);
  Future<void> delete(String id) => _repository.delete(id);
}
