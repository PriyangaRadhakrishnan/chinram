import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/farm/models/farm_income_model.dart';
import 'package:chinram_app/features/farm/repositories/hive_farm_income_repository.dart';

void main() {
  group('FarmIncomeModel Unit Tests', () {
    test('FarmIncomeModel serialization & deserialization works for milk', () {
      final model = FarmIncomeModel(
        id: 'milk-1',
        date: DateTime(2026, 7, 6),
        category: 'Milk',
        productName: 'Milk',
        quantity: 150.0,
        unit: 'Litres',
        pricePerUnit: 40.0,
        totalAmount: 6000.0,
        notes: 'Weekly milk delivery to society',
        fromDate: DateTime(2026, 6, 30),
        toDate: DateTime(2026, 7, 6),
      );

      final json = model.toJson();
      expect(json['id'], 'milk-1');
      expect(json['fromDate'], DateTime(2026, 6, 30).toIso8601String());
      expect(json['toDate'], DateTime(2026, 7, 6).toIso8601String());

      final decoded = FarmIncomeModel.fromJson(json);
      expect(decoded.id, 'milk-1');
      expect(decoded.category, 'Milk');
      expect(decoded.fromDate, DateTime(2026, 6, 30));
      expect(decoded.toDate, DateTime(2026, 7, 6));
    });

    test('FarmIncomeModel serialization is backward compatible with coconut', () {
      final model = FarmIncomeModel(
        id: 'coconut-1',
        date: DateTime(2026, 7, 6),
        category: 'Coconut',
        productName: 'Coconut',
        quantity: 500.0,
        unit: 'Pcs',
        pricePerUnit: 15.0,
        totalAmount: 7500.0,
        notes: 'Standard batch sale',
      );

      final json = model.toJson();
      expect(json['id'], 'coconut-1');
      expect(json.containsKey('fromDate'), false);
      expect(json.containsKey('toDate'), false);

      final decoded = FarmIncomeModel.fromJson(json);
      expect(decoded.id, 'coconut-1');
      expect(decoded.category, 'Coconut');
      expect(decoded.fromDate, null);
      expect(decoded.toDate, null);
    });
  });

  group('HiveFarmIncomeRepository Integration Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_farm_income_test');
      Hive.init(tempDir.path);
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('saves and retrieves milk, coconut and custom records correctly', () async {
      final repo = HiveFarmIncomeRepository();

      final record1 = FarmIncomeModel(
        id: 'id-1',
        date: DateTime(2026, 7, 6),
        category: 'Milk',
        productName: 'Milk',
        quantity: 150.0,
        unit: 'Litres',
        pricePerUnit: 40.0,
        totalAmount: 6000.0,
        fromDate: DateTime(2026, 6, 30),
        toDate: DateTime(2026, 7, 6),
      );

      final record2 = FarmIncomeModel(
        id: 'id-2',
        date: DateTime(2026, 7, 5),
        category: 'Coconut',
        productName: 'Coconut',
        quantity: 500.0,
        unit: 'Pcs',
        pricePerUnit: 15.0,
        totalAmount: 7500.0,
      );

      final record3 = FarmIncomeModel(
        id: 'id-3',
        date: DateTime(2026, 7, 4),
        category: 'Others',
        productName: 'Tomato',
        quantity: 80.0,
        unit: 'Kg',
        pricePerUnit: 35.0,
        totalAmount: 2800.0,
        notes: 'Tomato batch sale',
      );

      await repo.add(record1);
      await repo.add(record2);
      await repo.add(record3);

      final all = await repo.getAll();
      expect(all.length, 3);

      // Verify sorting order: date descending
      expect(all[0].id, 'id-1');
      expect(all[1].id, 'id-2');
      expect(all[2].id, 'id-3');

      final retrieved1 = await repo.getById('id-1');
      expect(retrieved1?.category, 'Milk');
      expect(retrieved1?.fromDate, DateTime(2026, 6, 30));
      expect(retrieved1?.toDate, DateTime(2026, 7, 6));
      expect(retrieved1?.totalAmount, 6000.0);

      final retrieved2 = await repo.getById('id-2');
      expect(retrieved2?.category, 'Coconut');
      expect(retrieved2?.fromDate, null);
      expect(retrieved2?.totalAmount, 7500.0);

      final retrieved3 = await repo.getById('id-3');
      expect(retrieved3?.category, 'Others');
      expect(retrieved3?.productName, 'Tomato');
      expect(retrieved3?.unit, 'Kg');
      expect(retrieved3?.quantity, 80.0);
      expect(retrieved3?.totalAmount, 2800.0);

      // Test update
      final updated1 = record1.copyWith(notes: 'Updated milk notes');
      await repo.update(updated1);
      final retrievedUpdated = await repo.getById('id-1');
      expect(retrievedUpdated?.notes, 'Updated milk notes');

      // Test delete
      await repo.delete('id-1');
      final afterDelete = await repo.getAll();
      expect(afterDelete.length, 2);
      expect(afterDelete[0].id, 'id-2');
      expect(afterDelete[1].id, 'id-3');
    });
  });
}
