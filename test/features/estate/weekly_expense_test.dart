import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/weekly_expense_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_weekly_expense_repository.dart';

void main() {
  group('WeeklyExpenseModel Unit Tests', () {
    test('converts to and from JSON', () {
      final expense = WeeklyExpenseModel(
        id: 'exp-1',
        date: '2026-07-01',
        category: 'Petrol',
        amount: 1200.50,
        notes: 'Filled tank for estate tractor',
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = expense.toJson();
      expect(json['id'], 'exp-1');
      expect(json['category'], 'Petrol');
      expect(json['amount'], 1200.50);
      expect(json['notes'], 'Filled tank for estate tractor');

      final fromJson = WeeklyExpenseModel.fromJson(json);
      expect(fromJson.id, 'exp-1');
      expect(fromJson.date, '2026-07-01');
      expect(fromJson.category, 'Petrol');
      expect(fromJson.amount, 1200.50);
      expect(fromJson.notes, 'Filled tank for estate tractor');
      expect(fromJson.createdDate, '2026-07-03');
      expect(fromJson.lastUpdatedTime, '12:00:00');
    });

    test('supports copyWith', () {
      final expense = WeeklyExpenseModel(
        id: 'exp-1',
        date: '2026-07-01',
        category: 'Others',
        customCategoryName: 'Electricity',
        amount: 2500.00,
        notes: 'Office bill',
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final updated = expense.copyWith(
        amount: 3000.00,
        lastUpdatedTime: '13:00:00',
      );

      expect(updated.id, 'exp-1');
      expect(updated.category, 'Others');
      expect(updated.customCategoryName, 'Electricity');
      expect(updated.amount, 3000.00);
      expect(updated.lastUpdatedTime, '13:00:00');
    });
  });

  group('HiveWeeklyExpenseRepository Unit Tests', () {
    late Directory tempDir;
    late HiveWeeklyExpenseRepository repo;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_expense_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repo = HiveWeeklyExpenseRepository();
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('starts with an empty list', () async {
      final list = await repo.getAll();
      expect(list, isEmpty);
    });

    test('saves, retrieves, updates, and deletes expense records in Hive', () async {
      final expense = WeeklyExpenseModel(
        id: 'exp-unique',
        date: '2026-07-01',
        category: 'Brush Cutter',
        amount: 450.00,
        notes: 'Blade replacement',
        createdDate: '2026-07-03',
        createdTime: '15:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '15:00:00',
      );

      // Save
      await repo.save(expense);

      // Get All
      var all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'exp-unique');
      expect(all.first.amount, 450.00);

      // Get by ID
      final retrieved = await repo.getById('exp-unique');
      expect(retrieved, isNotNull);
      expect(retrieved!.notes, 'Blade replacement');

      // Update
      final updated = expense.copyWith(
        amount: 500.00,
        notes: 'Blade replacement and sharpening',
        lastUpdatedTime: '16:00:00',
      );
      await repo.save(updated);

      final retrievedUpdated = await repo.getById('exp-unique');
      expect(retrievedUpdated!.amount, 500.00);
      expect(retrievedUpdated.notes, 'Blade replacement and sharpening');

      // Delete
      await repo.delete('exp-unique');
      all = await repo.getAll();
      expect(all, isEmpty);
    });
  });
}
