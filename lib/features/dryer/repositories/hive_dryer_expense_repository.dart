import 'package:hive/hive.dart';
import '../models/dryer_expense_model.dart';
import 'dryer_expense_repository.dart';

class HiveDryerExpenseRepository implements DryerExpenseRepository {
  static const String boxName = 'dryer_expenses_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(boxName);
  }

  @override
  Future<List<DryerExpense>> getAll() async {
    final box = await _getBox();
    final List<DryerExpense> expenses = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        expenses.add(DryerExpense.fromJson(value));
      } else {
        throw FormatException('Invalid dryer expense record format for key "$key"');
      }
    }
    expenses.sort(DryerExpense.compareNewestFirst);
    return expenses;
  }

  @override
  Future<DryerExpense?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value == null) return null;
    if (value is Map) {
      return DryerExpense.fromJson(value);
    }
    throw FormatException('Invalid dryer expense record format for id "$id"');
  }

  @override
  Future<void> add(DryerExpense expense) async {
    final box = await _getBox();
    await box.put(expense.id, expense.toJson());
  }

  @override
  Future<void> update(DryerExpense expense) async {
    final box = await _getBox();
    if (!box.containsKey(expense.id)) {
      throw StateError('Expense record not found');
    }
    await box.put(expense.id, expense.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
