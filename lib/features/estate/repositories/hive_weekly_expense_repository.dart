import 'package:hive/hive.dart';
import '../models/weekly_expense_model.dart';
import 'weekly_expense_repository.dart';

class HiveWeeklyExpenseRepository implements WeeklyExpenseRepository {
  static const String _boxName = 'weekly_expenses_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<WeeklyExpenseModel>> getAll() async {
    final box = await _getBox();
    final List<WeeklyExpenseModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(WeeklyExpenseModel.fromJson(value));
      }
    }
    // Sort chronologically by date descending
    list.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.createdTime.compareTo(a.createdTime);
    });
    return list;
  }

  @override
  Future<WeeklyExpenseModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return WeeklyExpenseModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> save(WeeklyExpenseModel expense) async {
    final box = await _getBox();
    await box.put(expense.id, expense.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
