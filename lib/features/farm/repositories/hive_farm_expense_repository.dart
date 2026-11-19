import 'package:hive/hive.dart';
import '../models/farm_expense_model.dart';
import 'farm_expense_repository.dart';

class HiveFarmExpenseRepository implements FarmExpenseRepository {
  static const String _boxName = 'farm_expenses_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<FarmExpenseModel>> getAll() async {
    final box = await _getBox();
    final List<FarmExpenseModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(FarmExpenseModel.fromJson(value));
      }
    }
    // Sort chronologically by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<FarmExpenseModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return FarmExpenseModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> add(FarmExpenseModel expense) async {
    final box = await _getBox();
    await box.put(expense.id, expense.toJson());
  }

  @override
  Future<void> update(FarmExpenseModel expense) async {
    final box = await _getBox();
    await box.put(expense.id, expense.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
