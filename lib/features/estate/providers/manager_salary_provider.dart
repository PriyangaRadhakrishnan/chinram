import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manager_salary_model.dart';
import '../repositories/manager_salary_repository.dart';
import '../repositories/hive_manager_salary_repository.dart';
import '../services/manager_salary_service.dart';

final managerSalaryRepositoryProvider = Provider<ManagerSalaryRepository>((ref) {
  return HiveManagerSalaryRepository();
});

final managerSalaryServiceProvider = Provider<ManagerSalaryService>((ref) {
  final repository = ref.watch(managerSalaryRepositoryProvider);
  return ManagerSalaryService(repository);
});

class ManagerSalaryListNotifier extends AsyncNotifier<List<ManagerSalaryModel>> {
  late final ManagerSalaryService _service;

  @override
  Future<List<ManagerSalaryModel>> build() async {
    _service = ref.watch(managerSalaryServiceProvider);
    return _service.getAll();
  }

  Future<void> addManagerSalary(ManagerSalaryModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(record);
      return _service.getAll();
    });
  }

  Future<void> updateManagerSalary(ManagerSalaryModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(record);
      return _service.getAll();
    });
  }

  Future<void> deleteManagerSalary(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final managerSalaryListProvider = AsyncNotifierProvider<ManagerSalaryListNotifier, List<ManagerSalaryModel>>(() {
  return ManagerSalaryListNotifier();
});
