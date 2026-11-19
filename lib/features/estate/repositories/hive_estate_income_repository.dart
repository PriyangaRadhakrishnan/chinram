import 'package:hive/hive.dart';
import '../models/estate_income_model.dart';
import 'estate_income_repository.dart';

class HiveEstateIncomeRepository implements EstateIncomeRepository {
  static const String _boxName = 'estate_incomes_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<EstateIncomeModel>> getAll() async {
    final box = await _getBox();
    final List<EstateIncomeModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(EstateIncomeModel.fromJson(value));
      }
    }
    // Sort chronologically by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<EstateIncomeModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return EstateIncomeModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> add(EstateIncomeModel income) async {
    final box = await _getBox();
    await box.put(income.id, income.toJson());
  }

  @override
  Future<void> update(EstateIncomeModel income) async {
    final box = await _getBox();
    await box.put(income.id, income.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
