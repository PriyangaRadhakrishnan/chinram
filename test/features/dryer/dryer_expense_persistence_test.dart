import 'dart:io';

import 'package:chinram_app/features/dryer/models/dryer_customer_model.dart';
import 'package:chinram_app/features/dryer/models/dryer_expense_model.dart';
import 'package:chinram_app/features/dryer/models/dryer_visit_model.dart';
import 'package:chinram_app/features/dryer/providers/dryer_expense_provider.dart';
import 'package:chinram_app/features/dryer/providers/dryer_provider.dart';
import 'package:chinram_app/features/dryer/repositories/hive_dryer_expense_repository.dart';
import 'package:chinram_app/features/dryer/services/dryer_expense_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('DryerExpense Model & Service Unit Tests', () {
    test('serializes and deserializes DryerExpense accurately including notes',
        () {
      final created = DateTime(2026, 11, 12, 10, 30);
      final updated = DateTime(2026, 11, 12, 11, 0);
      final expense = DryerExpense(
        id: 'dexp_1',
        date: DateTime(2026, 11, 12),
        category: 'Electricity Bill',
        amount: 2450.75,
        notes: 'Three-phase meter reading',
        createdAt: created,
        updatedAt: updated,
      );

      final roundTrip = DryerExpense.fromJson(expense.toJson());
      expect(roundTrip.id, 'dexp_1');
      expect(roundTrip.date, DateTime(2026, 11, 12));
      expect(roundTrip.category, 'Electricity Bill');
      expect(roundTrip.amount, 2450.75);
      expect(roundTrip.notes, 'Three-phase meter reading');
      expect(roundTrip.createdAt, created);
      expect(roundTrip.updatedAt, updated);
    });

    test('fromJson throws FormatException on corrupted or invalid fields', () {
      expect(
        () => DryerExpense.fromJson({'id': '', 'category': 'Fuel', 'amount': 10}),
        throwsFormatException,
      );
      expect(
        () => DryerExpense.fromJson({
          'id': 'dexp_1',
          'date': DateTime(2026, 11, 12).toIso8601String(),
          'category': 'Fuel',
          'amount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }),
        throwsFormatException,
      );
    });

    test('extractUniqueCategories derives sorted deduplicated labels', () {
      final now = DateTime.now();
      final expenses = [
        DryerExpense(
          id: '1',
          date: now,
          category: 'Transport',
          amount: 500,
          createdAt: now,
          updatedAt: now,
        ),
        DryerExpense(
          id: '2',
          date: now,
          category: 'electricity',
          amount: 800,
          createdAt: now,
          updatedAt: now,
        ),
        DryerExpense(
          id: '3',
          date: now,
          category: 'Electricity',
          amount: 900,
          createdAt: now,
          updatedAt: now,
        ),
        DryerExpense(
          id: '4',
          date: now,
          category: 'Bearing Repair',
          amount: 350,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(
        DryerExpenseService.extractUniqueCategories(expenses),
        ['Bearing Repair', 'electricity', 'Transport'],
      );
    });
  });

  group('DryerExpenseService & Hive Persistence Integration Tests', () {
    late Directory tempDir;
    late HiveDryerExpenseRepository expenseRepo;
    late DryerExpenseService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dryer_expense_test_');
      Hive.init(tempDir.path);
      expenseRepo = HiveDryerExpenseRepository();
      service = DryerExpenseService(expenseRepo);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rejects empty category and non-positive or non-finite amounts',
        () async {
      await expectLater(
        () => service.addExpense(
          date: DateTime(2026, 11, 12),
          category: '   ',
          amount: 100,
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => service.addExpense(
          date: DateTime(2026, 11, 12),
          category: 'Fuel',
          amount: 0,
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => service.addExpense(
          date: DateTime(2026, 11, 12),
          category: 'Fuel',
          amount: -25.5,
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => service.addExpense(
          date: DateTime(2026, 11, 12),
          category: 'Fuel',
          amount: double.nan,
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => service.addExpense(
          date: DateTime(2026, 11, 12),
          category: 'Fuel',
          amount: double.infinity,
        ),
        throwsArgumentError,
      );
    });

    test('adds decimal expenses, sorts newest first, edits only target, deletes only target',
        () async {
      final first = await service.addExpense(
        date: DateTime(2026, 11, 5),
        category: 'Firewood Supply',
        amount: 1250.5,
        notes: '2 loads',
      );
      final second = await service.addExpense(
        date: DateTime(2026, 11, 12),
        category: 'Electricity',
        amount: 3420.75,
        notes: 'Monthly bill',
      );
      final third = await service.addExpense(
        date: DateTime(2026, 11, 12),
        category: 'Blower Belt',
        amount: 450.25,
      );

      var list = await service.getAllExpenses();
      expect(list.length, 3);
      // Same date (Nov 12): most recently created (third) comes first, then second, then first (Nov 5)
      expect(list[0].id, third.id);
      expect(list[1].id, second.id);
      expect(list[2].id, first.id);
      expect(list[2].amount, 1250.5);
      expect(list[0].notes, isNull);

      // Edit only second expense (and clear its notes)
      final updatedSecond = await service.updateExpense(
        existingExpense: second,
        date: DateTime(2026, 11, 11),
        category: 'Electricity & Diesel',
        amount: 3500.99,
        notes: '   ',
      );
      expect(updatedSecond.id, second.id);
      expect(updatedSecond.category, 'Electricity & Diesel');
      expect(updatedSecond.amount, 3500.99);
      expect(updatedSecond.notes, isNull);

      list = await service.getAllExpenses();
      expect(list.length, 3);
      final loadedFirst = list.firstWhere((e) => e.id == first.id);
      expect(loadedFirst.category, 'Firewood Supply');
      expect(loadedFirst.amount, 1250.5);
      expect(loadedFirst.notes, '2 loads');

      // Delete only first expense
      await service.deleteExpense(first.id);
      list = await service.getAllExpenses();
      expect(list.length, 2);
      expect(list.any((e) => e.id == first.id), isFalse);
      expect(list.any((e) => e.id == second.id), isTrue);
      expect(list.any((e) => e.id == third.id), isTrue);
    });

    test('persists expenses across app restart (Hive close + reopen)', () async {
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      await container1.read(dryerExpensesProvider.future);
      final saved =
          await container1.read(dryerExpensesProvider.notifier).addExpense(
                date: DateTime(2026, 11, 12),
                category: 'Generator Maintenance',
                amount: 1875.5,
                notes: 'Oil and filter change',
              );

      // Simulate closing and reopening the app
      await Hive.close();
      Hive.init(tempDir.path);

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final loaded = await container2.read(dryerExpensesProvider.future);
      expect(loaded.length, 1);
      expect(loaded.first.id, saved.id);
      expect(loaded.first.date, DateTime(2026, 11, 12));
      expect(loaded.first.category, 'Generator Maintenance');
      expect(loaded.first.amount, 1875.5);
      expect(loaded.first.notes, 'Oil and filter change');
    });

    test(
        'remains completely isolated from Estate, Farm, and Phase 1 Dryer boxes',
        () async {
      final estateBox = await Hive.openBox('weekly_expenses_box');
      await estateBox.put('est_1', {'id': 'est_1', 'amount': 999});

      final farmBox = await Hive.openBox('farm_expenses_box');
      await farmBox.put('farm_1', {'id': 'farm_1', 'amount': 888});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Phase 1 customer & visit still works alongside Dryer expenses
      await container.read(dryerCustomersProvider.future);
      await container.read(dryerCustomersProvider.notifier).saveCustomerAndVisit(
            name: 'Ramesh',
            phoneNumber: '9876543210',
            address: 'Hill Road',
            areaType: DryerAreaType.acre,
            areaValue: 2,
            visitDate: DateTime(2026, 11, 12),
            greenQuantity: 600,
            product: DryerProduct.cardamom,
            dryQuantity: 120,
            rate: 10,
          );

      final expense =
          await container.read(dryerExpensesProvider.notifier).addExpense(
                date: DateTime(2026, 11, 12),
                category: 'Transport',
                amount: 650.25,
                notes: 'Pickup van',
              );
      await container
          .read(dryerExpensesProvider.notifier)
          .deleteExpense(expense.id);

      // Estate, Farm, and Phase 1 Dryer records are completely untouched
      expect(estateBox.length, 1);
      expect(estateBox.get('est_1')['amount'], 999);
      expect(farmBox.length, 1);
      expect(farmBox.get('farm_1')['amount'], 888);

      final summaries = await container.read(dryerCustomersProvider.future);
      expect(summaries.length, 1);
      expect(summaries.first.customer.name, 'Ramesh');
      expect(summaries.first.latestVisit?.charges, 6000.0);
    });
  });
}
