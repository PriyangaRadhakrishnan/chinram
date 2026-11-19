import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/farm/models/farm_expense_model.dart';
import 'package:chinram_app/features/farm/repositories/hive_farm_expense_repository.dart';

void main() {
  // Setup Hive for local tests
  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('FarmExpenseModel Unit Tests', () {
    test('converts to and from JSON correctly', () {
      final model = FarmExpenseModel(
        id: 'test-1',
        date: DateTime(2026, 7, 11),
        category: 'Coconut',
        amount: 8500.0,
        notes: 'Coconut harvest work',
        vettuWorkersCount: 5,
        vettuWorkerAmount: 4000.0,
        chithuWorkersCount: 4,
        chithuWorkerAmount: 3000.0,
        teaExpense: 500.0,
        otherExpenses: const [
          OtherExpenseItem(name: 'Transport', amount: 1000.0),
        ],
      );

      final json = model.toJson();
      expect(json['id'], 'test-1');
      expect(json['category'], 'Coconut');
      expect(json['amount'], 8500.0);
      expect(json['vettuWorkersCount'], 5);
      expect(json['otherExpenses'].length, 1);
      expect(json['otherExpenses'][0]['name'], 'Transport');

      final fromJson = FarmExpenseModel.fromJson(json);
      expect(fromJson.id, 'test-1');
      expect(fromJson.category, 'Coconut');
      expect(fromJson.amount, 8500.0);
      expect(fromJson.vettuWorkersCount, 5);
      expect(fromJson.otherExpenses?.length, 1);
      expect(fromJson.otherExpenses?[0].name, 'Transport');
      expect(fromJson.otherExpenses?[0].amount, 1000.0);
    });

    test('supports copyWith', () {
      final model = FarmExpenseModel(
        id: 'test-2',
        date: DateTime(2026, 7, 11),
        category: 'Milk',
        subCategory: 'Feed',
        amount: 3200.0,
        productName: 'Rice Bran',
        quantity: 4.0,
        unit: 'Sacks',
      );

      final copy = model.copyWith(amount: 3500.0, quantity: 5.0);
      expect(copy.id, 'test-2');
      expect(copy.amount, 3500.0);
      expect(copy.quantity, 5.0);
      expect(copy.productName, 'Rice Bran');
    });
  });

  group('HiveFarmExpenseRepository Integration Tests', () {
    test('saves, retrieves, updates, and deletes records successfully', () async {
      final repo = HiveFarmExpenseRepository();

      final record1 = FarmExpenseModel(
        id: 'exp-1',
        date: DateTime(2026, 7, 11),
        category: 'Coconut',
        amount: 5000.0,
        vettuWorkersCount: 3,
        vettuWorkerAmount: 3000.0,
        chithuWorkersCount: 2,
        chithuWorkerAmount: 1800.0,
        teaExpense: 200.0,
      );

      final record2 = FarmExpenseModel(
        id: 'exp-2',
        date: DateTime(2026, 7, 10),
        category: 'Milk',
        subCategory: 'Doctor',
        amount: 1500.0,
        notes: 'Cattle vaccination checkup',
      );

      final record3 = FarmExpenseModel(
        id: 'exp-3',
        date: DateTime(2026, 7, 9),
        category: 'Others',
        amount: 2500.0,
        productName: 'Fence Repair',
        notes: 'Repaired southern boundary fence',
      );

      // Add records
      await repo.add(record1);
      await repo.add(record2);
      await repo.add(record3);

      final all = await repo.getAll();
      expect(all.length, 3);

      // Verify sorting order: date descending
      expect(all[0].id, 'exp-1');
      expect(all[1].id, 'exp-2');
      expect(all[2].id, 'exp-3');

      // Retrieve by ID
      final retrieved1 = await repo.getById('exp-1');
      expect(retrieved1?.category, 'Coconut');
      expect(retrieved1?.amount, 5000.0);
      expect(retrieved1?.vettuWorkersCount, 3);

      final retrieved2 = await repo.getById('exp-2');
      expect(retrieved2?.category, 'Milk');
      expect(retrieved2?.subCategory, 'Doctor');
      expect(retrieved2?.amount, 1500.0);

      final retrieved3 = await repo.getById('exp-3');
      expect(retrieved3?.category, 'Others');
      expect(retrieved3?.productName, 'Fence Repair');

      // Update record
      final updated1 = record1.copyWith(amount: 5200.0, teaExpense: 400.0);
      await repo.update(updated1);
      final retrievedUpdated = await repo.getById('exp-1');
      expect(retrievedUpdated?.amount, 5200.0);
      expect(retrievedUpdated?.teaExpense, 400.0);

      // Delete record
      await repo.delete('exp-1');
      final afterDelete = await repo.getAll();
      expect(afterDelete.length, 2);
      expect(afterDelete[0].id, 'exp-2');
      expect(afterDelete[1].id, 'exp-3');
    });
  });
}
