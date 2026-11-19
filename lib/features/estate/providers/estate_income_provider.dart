import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estate_income_model.dart';
import '../repositories/estate_income_repository.dart';
import '../repositories/hive_estate_income_repository.dart';
import '../services/estate_income_service.dart';

final estateIncomeRepositoryProvider = Provider<EstateIncomeRepository>((ref) {
  return HiveEstateIncomeRepository();
});

final estateIncomeServiceProvider = Provider<EstateIncomeService>((ref) {
  final repository = ref.watch(estateIncomeRepositoryProvider);
  return EstateIncomeService(repository);
});

class EstateIncomeListNotifier extends AsyncNotifier<List<EstateIncomeModel>> {
  late final EstateIncomeService _service;

  @override
  Future<List<EstateIncomeModel>> build() async {
    _service = ref.watch(estateIncomeServiceProvider);
    return _service.getAll();
  }

  Future<void> addIncome(EstateIncomeModel income) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.add(income);
      return _service.getAll();
    });
  }

  Future<void> updateIncome(EstateIncomeModel income) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.update(income);
      return _service.getAll();
    });
  }

  Future<void> deleteIncome(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final estateIncomeListProvider = AsyncNotifierProvider<EstateIncomeListNotifier, List<EstateIncomeModel>>(() {
  return EstateIncomeListNotifier();
});
