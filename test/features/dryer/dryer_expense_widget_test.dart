import 'dart:async';

import 'package:chinram_app/features/dryer/models/dryer_customer_model.dart';
import 'package:chinram_app/features/dryer/models/dryer_expense_model.dart';
import 'package:chinram_app/features/dryer/models/dryer_visit_model.dart';
import 'package:chinram_app/features/dryer/providers/dryer_expense_provider.dart';
import 'package:chinram_app/features/dryer/providers/dryer_provider.dart';
import 'package:chinram_app/features/dryer/repositories/dryer_customer_repository.dart';
import 'package:chinram_app/features/dryer/repositories/dryer_expense_repository.dart';
import 'package:chinram_app/features/dryer/repositories/dryer_visit_repository.dart';
import 'package:chinram_app/features/dryer/screens/dryer_add_form_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_expense_detail_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_expense_form_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_other_expenses_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_screen.dart';
import 'package:chinram_app/features/dryer/services/dryer_expense_service.dart';
import 'package:chinram_app/features/dryer/utils/dryer_calculator.dart';
import 'package:chinram_app/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _InMemoryDryerCustomerRepository implements DryerCustomerRepository {
  final Map<String, DryerCustomer> _store = {};

  @override
  Future<void> add(DryerCustomer customer) async =>
      _store[customer.id] = customer;

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Future<List<DryerCustomer>> getAll() async => _store.values.toList();

  @override
  Future<DryerCustomer?> getById(String id) async => _store[id];

  @override
  Future<DryerCustomer?> getByPhoneNumber(String phoneNumber) async {
    final target = DryerCalculator.normalizePhoneNumber(phoneNumber);
    for (final c in _store.values) {
      if (DryerCalculator.normalizePhoneNumber(c.phoneNumber) == target) {
        return c;
      }
    }
    return null;
  }

  @override
  Future<void> update(DryerCustomer customer) async =>
      _store[customer.id] = customer;
}

class _InMemoryDryerVisitRepository implements DryerVisitRepository {
  final Map<String, DryerVisit> _store = {};

  @override
  Future<void> add(DryerVisit visit) async => _store[visit.id] = visit;

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Future<void> deleteByCustomerId(String customerId) async =>
      _store.removeWhere((_, v) => v.customerId == customerId);

  @override
  Future<List<DryerVisit>> getAll() async => _store.values.toList();

  @override
  Future<List<DryerVisit>> getByCustomerId(String customerId) async =>
      _store.values.where((v) => v.customerId == customerId).toList();

  @override
  Future<DryerVisit?> getById(String id) async => _store[id];

  @override
  Future<void> update(DryerVisit visit) async => _store[visit.id] = visit;
}

class _InMemoryDryerExpenseRepository implements DryerExpenseRepository {
  final Map<String, DryerExpense> _store = {};
  final Completer<void>? addGate;
  bool shouldThrowOnGetAll;

  _InMemoryDryerExpenseRepository({
    this.addGate,
    this.shouldThrowOnGetAll = false,
  });

  @override
  Future<void> add(DryerExpense expense) async {
    if (addGate != null && !addGate!.isCompleted) {
      await addGate!.future;
    }
    _store[expense.id] = expense;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<DryerExpense>> getAll() async {
    if (shouldThrowOnGetAll) {
      throw Exception('Simulated storage failure');
    }
    final list = _store.values.toList();
    list.sort(DryerExpense.compareNewestFirst);
    return list;
  }

  @override
  Future<DryerExpense?> getById(String id) async => _store[id];

  @override
  Future<void> update(DryerExpense expense) async {
    if (!_store.containsKey(expense.id)) {
      throw StateError('Expense not found');
    }
    _store[expense.id] = expense;
  }
}

void main() {
  GoRouter buildTestRouter({String initialLocation = '/dryer'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/dryer',
          builder: (context, state) => const DryerScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => DryerAddFormScreen(
                initialCustomerId: state.uri.queryParameters['customerId'],
              ),
            ),
            GoRoute(
              path: 'expenses',
              builder: (context, state) => const DryerOtherExpensesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const DryerExpenseFormScreen(),
                ),
                GoRoute(
                  path: 'detail/:expenseId',
                  builder: (context, state) => DryerExpenseDetailScreen(
                    expenseId: state.pathParameters['expenseId']!,
                  ),
                ),
                GoRoute(
                  path: 'edit/:expenseId',
                  builder: (context, state) => DryerExpenseFormScreen(
                    expenseId: state.pathParameters['expenseId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  testWidgets(
      'Navigates from DryerScreen to Other Expenses, validates inputs, prevents double-tap duplicate save, and adds decimal expense',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final gate = Completer<void>();
    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository();
    final expenseRepo = _InMemoryDryerExpenseRepository(addGate: gate);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
          dryerExpenseRepositoryProvider.overrideWithValue(expenseRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Dryer module provides access to Customers and Other Expenses
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Other Expenses'), findsOneWidget);

    await tester.tap(find.text('Other Expenses'));
    await tester.pumpAndSettle();

    // Independent Other Expenses screen with empty state & Add Expense FAB
    expect(find.text('No Other Expenses Yet'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Add Other Expense'), findsOneWidget);
    // Free-text Expense Category input (no DropdownButtonFormField)
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    // Reject empty required fields
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Expense category is required'), findsOneWidget);
    expect(find.text('Amount is required'), findsOneWidget);

    // Reject invalid / zero / negative amounts
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expense Category *'),
      'Electricity Bill',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (₹) *'),
      '0',
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Amount must be greater than zero'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (₹) *'),
      '-50',
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Amount must be greater than zero'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (₹) *'),
      'abc',
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid Amount'), findsOneWidget);

    // Enter valid decimal amount and optional notes
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (₹) *'),
      '1450.75',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (Optional)'),
      'Meter reading #42',
    );

    // Double-tap Save rapidly -> only 1 record created
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    gate.complete();
    await tester.pumpAndSettle();

    // Returned to Other Expenses list showing new record
    expect(find.text('Electricity Bill'), findsWidgets);
    expect(find.text('₹1,450.75'), findsOneWidget);
    expect(find.text('Meter reading #42'), findsOneWidget);
    final saved = await expenseRepo.getAll();
    expect(saved.length, 1);
  });

  testWidgets(
      'Supports search by category & notes, filter by date, date range & dynamic categories, and CRUD detail/edit/delete',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository();
    final expenseRepo = _InMemoryDryerExpenseRepository();
    final service = DryerExpenseService(expenseRepo);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final olderDate = todayDate.subtract(const Duration(days: 5));

    await service.addExpense(
      date: olderDate,
      category: 'Firewood',
      amount: 2000,
      notes: 'Dry oak logs',
    );
    await service.addExpense(
      date: todayDate,
      category: 'Blower Repair',
      amount: 750.5,
      notes: 'Replaced bearing',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
          dryerExpenseRepositoryProvider.overrideWithValue(expenseRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(initialLocation: '/dryer/expenses'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Newest first: Blower Repair (today) appears above Firewood (5 days ago)
    final blowerY = tester.getTopLeft(find.text('Blower Repair').last).dy;
    final firewoodY = tester.getTopLeft(find.text('Firewood').last).dy;
    expect(blowerY, lessThan(firewoodY));

    // Search by category
    await tester.enterText(find.byType(TextField).first, 'Firewood');
    await tester.pumpAndSettle();
    expect(find.text('₹2,000.00'), findsOneWidget);
    expect(find.text('₹750.50'), findsNothing);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    // Search by notes
    await tester.enterText(find.byType(TextField).first, 'bearing');
    await tester.pumpAndSettle();
    expect(find.text('₹750.50'), findsOneWidget);
    expect(find.text('₹2,000.00'), findsNothing);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    // Dynamic Category chip filter
    await tester.tap(find.widgetWithText(ChoiceChip, 'Firewood'));
    await tester.pumpAndSettle();
    expect(find.text('₹2,000.00'), findsOneWidget);
    expect(find.text('₹750.50'), findsNothing);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    // Specific Date filter (OK picks today -> only Blower Repair matches)
    await tester.tap(find.text('Specific Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('₹750.50'), findsOneWidget);
    expect(find.text('₹2,000.00'), findsNothing);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    // Date Range filter: pick today..today -> only Blower Repair matches
    await tester.tap(find.text('Date Range'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(todayDate.day.toString()).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(todayDate.day.toString()).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('₹750.50'), findsOneWidget);
    expect(find.text('₹2,000.00'), findsNothing);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    // Tap Blower Repair card -> View Details
    await tester.tap(find.text('₹750.50'));
    await tester.pumpAndSettle();
    expect(find.text('Expense Details'), findsOneWidget);
    expect(find.text('Blower Repair'), findsOneWidget);
    expect(find.text('Replaced bearing'), findsOneWidget);

    // Edit Expense -> prefilled values -> update
    await tester.tap(find.text('Edit Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Other Expense'), findsOneWidget);
    expect(find.text('750.5'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (₹) *'),
      '825.25',
    );
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Expense Details'), findsOneWidget);
    expect(find.text('₹825.25'), findsOneWidget);

    // Delete Expense with confirmation dialog -> other record remains intact
    await tester.tap(find.text('Delete Expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('₹825.25'), findsNothing);
    expect(find.text('₹2,000.00'), findsOneWidget);
    final remaining = await expenseRepo.getAll();
    expect(remaining.length, 1);
    expect(remaining.first.category, 'Firewood');
  });

  testWidgets(
      'Shows error state with retry and renders without RenderFlex overflow on narrow 320px screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository();
    final expenseRepo = _InMemoryDryerExpenseRepository(shouldThrowOnGetAll: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
          dryerExpenseRepositoryProvider.overrideWithValue(expenseRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(initialLocation: '/dryer/expenses'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Error state displayed
    expect(find.text('Error Loading Expenses'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Recover on Retry
    expenseRepo.shouldThrowOnGetAll = false;
    await expenseRepo.add(
      DryerExpense(
        id: 'dexp_long',
        date: DateTime(2026, 11, 12),
        category: 'Very Long Custom Dryer Maintenance Expense Category Name',
        amount: 12345.67,
        notes:
            'Detailed multi-line notes explaining urgent spare parts replacement for the cardamom dryer.',
        createdAt: DateTime(2026, 11, 12),
        updatedAt: DateTime(2026, 11, 12),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('₹12,345.67'), findsOneWidget);

    // Open Detail on 320px screen
    await tester.tap(find.text('₹12,345.67'));
    await tester.pumpAndSettle();
    expect(find.text('Expense Details'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Open Edit on 320px screen
    await tester.ensureVisible(find.text('Edit Expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Other Expense'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
