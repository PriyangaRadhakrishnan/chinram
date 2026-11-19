import 'package:hive/hive.dart';
import '../models/manager_salary_model.dart';
import 'manager_salary_repository.dart';

class HiveManagerSalaryRepository implements ManagerSalaryRepository {
  static const String _boxName = 'manager_salaries_box';

  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  @override
  Future<List<ManagerSalaryModel>> getAll() async {
    final box = await _getBox();
    final List<ManagerSalaryModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(ManagerSalaryModel.fromJson(value));
      }
    }
    // Sort by created Date & Time descending
    list.sort((a, b) {
      final dateCompare = b.createdDate.compareTo(a.createdDate);
      if (dateCompare != 0) return dateCompare;
      return b.createdTime.compareTo(a.createdTime);
    });
    return list;
  }

  @override
  Future<ManagerSalaryModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return ManagerSalaryModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> save(ManagerSalaryModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
