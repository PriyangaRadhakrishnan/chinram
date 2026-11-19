import 'package:hive/hive.dart';
import '../models/farm_income_model.dart';
import 'farm_income_repository.dart';

class HiveFarmIncomeRepository implements FarmIncomeRepository {
  static const String _boxName = 'farm_incomes_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<FarmIncomeModel>> getAll() async {
    final box = await _getBox();
    final List<FarmIncomeModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(FarmIncomeModel.fromJson(value));
      }
    }
    // Sort chronologically by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<FarmIncomeModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return FarmIncomeModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> add(FarmIncomeModel income) async {
    final box = await _getBox();
    await box.put(income.id, income.toJson());
  }

  @override
  Future<void> update(FarmIncomeModel income) async {
    final box = await _getBox();
    await box.put(income.id, income.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
