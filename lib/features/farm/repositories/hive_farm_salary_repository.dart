import 'package:hive/hive.dart';
import '../models/farm_salary_model.dart';
import 'farm_salary_repository.dart';

class HiveFarmSalaryRepository implements FarmSalaryRepository {
  static const String _boxName = 'farm_salaries_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<FarmSalaryModel>> getAll() async {
    final box = await _getBox();
    final List<FarmSalaryModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(FarmSalaryModel.fromJson(value));
      }
    }
    // Sort chronologically by date range start date descending
    list.sort((a, b) => b.fromDate.compareTo(a.fromDate));
    return list;
  }

  @override
  Future<FarmSalaryModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return FarmSalaryModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> add(FarmSalaryModel salary) async {
    final box = await _getBox();
    await box.put(salary.id, salary.toJson());
  }

  @override
  Future<void> update(FarmSalaryModel salary) async {
    final box = await _getBox();
    await box.put(salary.id, salary.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
