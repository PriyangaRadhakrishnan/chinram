import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_expense_model.dart';
import '../repositories/farm_expense_repository.dart';
import '../repositories/hive_farm_expense_repository.dart';
import '../services/farm_expense_service.dart';

final farmExpenseRepositoryProvider = Provider<FarmExpenseRepository>((ref) {
  return HiveFarmExpenseRepository();
});

final farmExpenseServiceProvider = Provider<FarmExpenseService>((ref) {
  final repository = ref.watch(farmExpenseRepositoryProvider);
  return FarmExpenseService(repository);
});

class FarmExpenseListNotifier extends AsyncNotifier<List<FarmExpenseModel>> {
  late final FarmExpenseService _service;

  @override
  Future<List<FarmExpenseModel>> build() async {
    _service = ref.watch(farmExpenseServiceProvider);
    return _service.getAll();
  }

  Future<void> addExpense(FarmExpenseModel expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.add(expense);
      return _service.getAll();
    });
  }

  Future<void> updateExpense(FarmExpenseModel expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.update(expense);
      return _service.getAll();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final farmExpenseListProvider = AsyncNotifierProvider<FarmExpenseListNotifier, List<FarmExpenseModel>>(() {
  return FarmExpenseListNotifier();
});
