import 'package:hive/hive.dart';
import '../models/salary_model.dart';
import '../models/salary_configuration_model.dart';
import 'salary_repository.dart';

class HiveSalaryRepository implements SalaryRepository {
  static const String _salariesBoxName = 'salaries_box';
  static const String _configBoxName = 'salary_config_box';

  Future<Box> _getSalariesBox() async => await Hive.openBox(_salariesBoxName);
  Future<Box> _getConfigBox() async => await Hive.openBox(_configBoxName);

  @override
  Future<List<SalaryModel>> getAll() async {
    final box = await _getSalariesBox();
    final List<SalaryModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(SalaryModel.fromJson(value));
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
  Future<SalaryModel?> getById(String id) async {
    final box = await _getSalariesBox();
    final value = box.get(id);
    if (value is Map) {
      return SalaryModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> save(SalaryModel salary) async {
    final box = await _getSalariesBox();
    await box.put(salary.id, salary.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getSalariesBox();
    await box.delete(id);
  }

  @override
  Future<SalaryConfigurationModel> getConfiguration() async {
    final box = await _getConfigBox();
    final value = box.get('config');
    if (value is Map) {
      return SalaryConfigurationModel.fromJson(value);
    }
    return const SalaryConfigurationModel(maleDailyWage: 800.0, femaleDailyWage: 700.0);
  }

  @override
  Future<void> saveConfiguration(SalaryConfigurationModel config) async {
    final box = await _getConfigBox();
    await box.put('config', config.toJson());
  }
}
