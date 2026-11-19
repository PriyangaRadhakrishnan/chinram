import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/estate_income_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_estate_income_repository.dart';

void main() {
  group('EstateIncomeModel Unit Tests', () {
    test('EstateIncomeModel serialization & deserialization works for cardamom', () {
      final model = EstateIncomeModel(
        id: 'cardamom-1',
        date: DateTime(2026, 7, 6),
        category: 'Cardamom',
        productName: 'Cardamom',
        quantity: 61.5,
        unit: 'Kg',
        pricePerUnit: 1450.0,
        totalAmount: 89175.0,
        notes: 'Top grade dry cardamom',
        greenQuantity: 380.0,
        dryQuantity: 61.5,
        percent: 6.18,
      );

      final json = model.toJson();
      expect(json['id'], 'cardamom-1');
      expect(json['greenQuantity'], 380.0);
      expect(json['dryQuantity'], 61.5);
      expect(json['percent'], 6.18);

      final decoded = EstateIncomeModel.fromJson(json);
      expect(decoded.id, 'cardamom-1');
      expect(decoded.category, 'Cardamom');
      expect(decoded.greenQuantity, 380.0);
      expect(decoded.dryQuantity, 61.5);
      expect(decoded.percent, 6.18);
    });

    test('EstateIncomeModel serialization is backward compatible with other categories', () {
      final model = EstateIncomeModel(
        id: 'coffee-1',
        date: DateTime(2026, 7, 6),
        category: 'Coffee',
        productName: 'Robusta Parchment',
        quantity: 150.0,
        unit: 'Kg',
        pricePerUnit: 180.0,
        totalAmount: 27000.0,
        notes: 'Bulk coffee harvest',
      );

      final json = model.toJson();
      expect(json['id'], 'coffee-1');
      expect(json.containsKey('greenQuantity'), false);
      expect(json.containsKey('dryQuantity'), false);
      expect(json.containsKey('percent'), false);

      final decoded = EstateIncomeModel.fromJson(json);
      expect(decoded.id, 'coffee-1');
      expect(decoded.category, 'Coffee');
      expect(decoded.greenQuantity, null);
      expect(decoded.dryQuantity, null);
      expect(decoded.percent, null);
    });
  });

  group('HiveEstateIncomeRepository Integration Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_estate_income_test');
      Hive.init(tempDir.path);
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('saves and retrieves cardamom and legacy records correctly', () async {
      final repo = HiveEstateIncomeRepository();

      final record1 = EstateIncomeModel(
        id: 'id-1',
        date: DateTime(2026, 7, 6),
        category: 'Cardamom',
        productName: 'Cardamom',
        quantity: 61.5,
        unit: 'Kg',
        pricePerUnit: 1450.0,
        totalAmount: 89175.0,
        greenQuantity: 380.0,
        dryQuantity: 61.5,
        percent: 6.18,
      );

      final record2 = EstateIncomeModel(
        id: 'id-2',
        date: DateTime(2026, 7, 5),
        category: 'Pepper',
        productName: 'Black Pepper',
        quantity: 50.0,
        unit: 'Kg',
        pricePerUnit: 350.0,
        totalAmount: 17500.0,
      );

      await repo.add(record1);
      await repo.add(record2);

      final all = await repo.getAll();
      expect(all.length, 2);

      // Verify sorting order: date descending
      expect(all[0].id, 'id-1');
      expect(all[1].id, 'id-2');

      final retrieved1 = await repo.getById('id-1');
      expect(retrieved1?.category, 'Cardamom');
      expect(retrieved1?.greenQuantity, 380.0);
      expect(retrieved1?.dryQuantity, 61.5);
      expect(retrieved1?.percent, 6.18);
      expect(retrieved1?.totalAmount, 89175.0);

      final retrieved2 = await repo.getById('id-2');
      expect(retrieved2?.category, 'Pepper');
      expect(retrieved2?.greenQuantity, null);
      expect(retrieved2?.totalAmount, 17500.0);

      // Test update
      final updated1 = record1.copyWith(notes: 'Updated note');
      await repo.update(updated1);
      final retrievedUpdated = await repo.getById('id-1');
      expect(retrievedUpdated?.notes, 'Updated note');

      // Test delete
      await repo.delete('id-1');
      final afterDelete = await repo.getAll();
      expect(afterDelete.length, 1);
      expect(afterDelete.first.id, 'id-2');
    });
  });
}
