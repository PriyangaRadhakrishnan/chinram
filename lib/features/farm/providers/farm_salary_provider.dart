import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_salary_model.dart';
import '../repositories/farm_salary_repository.dart';
import '../repositories/hive_farm_salary_repository.dart';
import '../services/farm_salary_service.dart';

final farmSalaryRepositoryProvider = Provider<FarmSalaryRepository>((ref) {
  return HiveFarmSalaryRepository();
});

final farmSalaryServiceProvider = Provider<FarmSalaryService>((ref) {
  final repository = ref.watch(farmSalaryRepositoryProvider);
  return FarmSalaryService(repository);
});

class FarmSalaryListNotifier extends AsyncNotifier<List<FarmSalaryModel>> {
  late final FarmSalaryService _service;

  @override
  Future<List<FarmSalaryModel>> build() async {
    _service = ref.watch(farmSalaryServiceProvider);
    return _service.getAll();
  }

  Future<void> addSalary(FarmSalaryModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.add(record);
      return _service.getAll();
    });
  }

  Future<void> updateSalary(FarmSalaryModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.update(record);
      return _service.getAll();
    });
  }

  Future<void> deleteSalary(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final farmSalaryListProvider = AsyncNotifierProvider<FarmSalaryListNotifier, List<FarmSalaryModel>>(() {
  return FarmSalaryListNotifier();
});
