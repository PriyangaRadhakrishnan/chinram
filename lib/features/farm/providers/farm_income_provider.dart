import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_income_model.dart';
import '../repositories/farm_income_repository.dart';
import '../repositories/hive_farm_income_repository.dart';
import '../services/farm_income_service.dart';

final farmIncomeRepositoryProvider = Provider<FarmIncomeRepository>((ref) {
  return HiveFarmIncomeRepository();
});

final farmIncomeServiceProvider = Provider<FarmIncomeService>((ref) {
  final repository = ref.watch(farmIncomeRepositoryProvider);
  return FarmIncomeService(repository);
});

class FarmIncomeListNotifier extends AsyncNotifier<List<FarmIncomeModel>> {
  late final FarmIncomeService _service;

  @override
  Future<List<FarmIncomeModel>> build() async {
    _service = ref.watch(farmIncomeServiceProvider);
    return _service.getAll();
  }

  Future<void> addIncome(FarmIncomeModel income) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.add(income);
      return _service.getAll();
    });
  }

  Future<void> updateIncome(FarmIncomeModel income) async {
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

final farmIncomeListProvider = AsyncNotifierProvider<FarmIncomeListNotifier, List<FarmIncomeModel>>(() {
  return FarmIncomeListNotifier();
});
