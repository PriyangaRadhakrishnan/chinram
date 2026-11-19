import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dryer_expense_model.dart';
import '../repositories/dryer_expense_repository.dart';
import '../repositories/hive_dryer_expense_repository.dart';
import '../services/dryer_expense_service.dart';

final dryerExpenseRepositoryProvider = Provider<DryerExpenseRepository>((ref) {
  return HiveDryerExpenseRepository();
});

final dryerExpenseServiceProvider = Provider<DryerExpenseService>((ref) {
  final repository = ref.watch(dryerExpenseRepositoryProvider);
  return DryerExpenseService(repository);
});

class DryerExpensesNotifier extends AsyncNotifier<List<DryerExpense>> {
  DryerExpenseService get _service => ref.read(dryerExpenseServiceProvider);

  @override
  Future<List<DryerExpense>> build() async {
    final service = ref.watch(dryerExpenseServiceProvider);
    return service.getAllExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getAllExpenses());
  }

  Future<DryerExpense> addExpense({
    required DateTime date,
    required String category,
    required double amount,
    String? notes,
  }) async {
    final created = await _service.addExpense(
      date: date,
      category: category,
      amount: amount,
      notes: notes,
    );
    final updatedList = await _service.getAllExpenses();
    state = AsyncValue.data(updatedList);
    return created;
  }

  Future<DryerExpense> updateExpense({
    required DryerExpense existingExpense,
    required DateTime date,
    required String category,
    required double amount,
    String? notes,
  }) async {
    final updated = await _service.updateExpense(
      existingExpense: existingExpense,
      date: date,
      category: category,
      amount: amount,
      notes: notes,
    );
    final updatedList = await _service.getAllExpenses();
    state = AsyncValue.data(updatedList);
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    await _service.deleteExpense(id);
    final updatedList = await _service.getAllExpenses();
    state = AsyncValue.data(updatedList);
  }
}

final dryerExpensesProvider =
    AsyncNotifierProvider<DryerExpensesNotifier, List<DryerExpense>>(() {
  return DryerExpensesNotifier();
});
