import '../models/dryer_expense_model.dart';
import '../repositories/dryer_expense_repository.dart';

class DryerExpenseService {
  final DryerExpenseRepository _repository;

  static int _idSequence = 0;

  const DryerExpenseService(this._repository);

  String _generateId() {
    _idSequence++;
    return 'dexp_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  Future<List<DryerExpense>> getAllExpenses() async {
    final expenses = await _repository.getAll();
    expenses.sort(DryerExpense.compareNewestFirst);
    return expenses;
  }

  Future<DryerExpense?> getExpenseById(String id) {
    return _repository.getById(id);
  }

  void _validateFields({
    required String category,
    required double amount,
  }) {
    if (category.trim().isEmpty) {
      throw ArgumentError('Expense category is required');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
  }

  String? _normalizeNotes(String? notes) {
    final trimmed = notes?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<DryerExpense> addExpense({
    required DateTime date,
    required String category,
    required double amount,
    String? notes,
  }) async {
    final trimmedCategory = category.trim();
    _validateFields(category: trimmedCategory, amount: amount);

    final now = DateTime.now();
    final expense = DryerExpense(
      id: _generateId(),
      date: DateTime(date.year, date.month, date.day),
      category: trimmedCategory,
      amount: amount,
      notes: _normalizeNotes(notes),
      createdAt: now,
      updatedAt: now,
    );

    await _repository.add(expense);
    return expense;
  }

  Future<DryerExpense> updateExpense({
    required DryerExpense existingExpense,
    required DateTime date,
    required String category,
    required double amount,
    String? notes,
  }) async {
    final trimmedCategory = category.trim();
    _validateFields(category: trimmedCategory, amount: amount);

    final normalizedNotes = _normalizeNotes(notes);
    final updated = existingExpense.copyWith(
      date: DateTime(date.year, date.month, date.day),
      category: trimmedCategory,
      amount: amount,
      notes: normalizedNotes,
      clearNotes: normalizedNotes == null,
      updatedAt: DateTime.now(),
    );

    await _repository.update(updated);
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    await _repository.delete(id);
  }

  /// Derives sorted unique category labels from actual saved expense records,
  /// deduplicated case-insensitively.
  static List<String> extractUniqueCategories(List<DryerExpense> expenses) {
    final Map<String, String> seen = {};
    for (final expense in expenses) {
      final trimmed = expense.category.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      seen.putIfAbsent(key, () => trimmed);
    }
    final categories = seen.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }
}
