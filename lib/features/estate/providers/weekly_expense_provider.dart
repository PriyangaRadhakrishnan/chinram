import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_expense_model.dart';
import '../repositories/weekly_expense_repository.dart';
import '../repositories/hive_weekly_expense_repository.dart';
import '../services/weekly_expense_service.dart';

final weeklyExpenseRepositoryProvider = Provider<WeeklyExpenseRepository>((ref) {
  return HiveWeeklyExpenseRepository();
});

final weeklyExpenseServiceProvider = Provider<WeeklyExpenseService>((ref) {
  final repository = ref.watch(weeklyExpenseRepositoryProvider);
  return WeeklyExpenseService(repository);
});

// Manage logs of weekly expenses
class WeeklyExpenseListNotifier extends AsyncNotifier<List<WeeklyExpenseModel>> {
  late final WeeklyExpenseService _service;

  @override
  Future<List<WeeklyExpenseModel>> build() async {
    _service = ref.watch(weeklyExpenseServiceProvider);
    return _service.getAll();
  }

  Future<void> addExpense(WeeklyExpenseModel expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(expense);
      return _service.getAll();
    });
  }

  Future<void> updateExpense(WeeklyExpenseModel expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(expense);
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

final weeklyExpenseListProvider = AsyncNotifierProvider<WeeklyExpenseListNotifier, List<WeeklyExpenseModel>>(() {
  return WeeklyExpenseListNotifier();
});
