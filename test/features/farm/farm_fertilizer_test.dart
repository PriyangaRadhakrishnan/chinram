import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/farm/models/farm_fertilizer_model.dart';
import 'package:chinram_app/features/farm/models/farm_organic_fertilizer_model.dart';
import 'package:chinram_app/features/farm/models/farm_fertilizer_usage_model.dart';
import 'package:chinram_app/features/farm/repositories/hive_farm_fertilizer_repository.dart';

void main() {
  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('FarmFertilizerModel Unit Tests', () {
    test('converts chemical fertilizer to and from JSON', () {
      final model = FarmFertilizerModel(
        id: 'chem-1',
        date: '2026-07-11',
        name: 'Urea',
        quantityPerBag: 50.0,
        unit: 'Kg',
        initialStock: 258.0,
        price: 12500.0,
        totalPrice: 12500.0,
        notes: 'Urea batch A',
        createdDate: '2026-07-11',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-11',
        lastUpdatedTime: '12:00:00',
      );

      final json = model.toJson();
      expect(json['id'], 'chem-1');
      expect(json['initialStock'], 258.0);
      expect(json['totalPrice'], 12500.0);

      final fromJson = FarmFertilizerModel.fromJson(json);
      expect(fromJson.id, 'chem-1');
      expect(fromJson.initialStock, 258.0);
      expect(fromJson.totalPrice, 12500.0);
    });

    test('converts organic fertilizer to and from JSON', () {
      final model = FarmOrganicFertilizerModel(
        id: 'org-1',
        date: '2026-07-11',
        name: 'Cow Dung',
        loads: 10.0,
        unit: 'Tractor',
        price: 15000.0,
        totalPrice: 15000.0,
        notes: 'Dryer block manuring',
        createdDate: '2026-07-11',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-11',
        lastUpdatedTime: '12:00:00',
      );

      final json = model.toJson();
      expect(json['id'], 'org-1');
      expect(json['loads'], 10.0);
      expect(json['unit'], 'Tractor');

      final fromJson = FarmOrganicFertilizerModel.fromJson(json);
      expect(fromJson.id, 'org-1');
      expect(fromJson.loads, 10.0);
      expect(fromJson.unit, 'Tractor');
    });

    test('converts chemical usages to and from JSON', () {
      final model = FarmFertilizerUsageModel(
        id: 'usage-1',
        date: '2026-07-11',
        fertilizerId: 'chem-1',
        bagsUsed: 2.5,
        notes: 'Applied on plot B',
        createdDate: '2026-07-11',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-11',
        lastUpdatedTime: '12:00:00',
      );

      final json = model.toJson();
      expect(json['bagsUsed'], 2.5);

      final fromJson = FarmFertilizerUsageModel.fromJson(json);
      expect(fromJson.bagsUsed, 2.5);
    });
  });

  group('HiveFarmFertilizerRepositories Integration Tests', () {
    test('Chemical inventory CRUD works correctly', () async {
      final repo = HiveFarmChemicalInventoryRepository();
      final record = FarmFertilizerModel(
        id: 'chem-t1',
        date: '2026-07-11',
        name: 'Potash',
        quantityPerBag: 50.0,
        unit: 'Kg',
        initialStock: 100.0,
        price: 8000.0,
        totalPrice: 8000.0,
        createdDate: '2026-07-11',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-11',
        lastUpdatedTime: '12:00:00',
      );

      await repo.add(record);
      final fetched = await repo.getById('chem-t1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Potash');
      expect(fetched.initialStock, 100.0);

      final updated = record.copyWith(name: 'Potash Update', initialStock: 95.5);
      await repo.update(updated);
      final refetched = await repo.getById('chem-t1');
      expect(refetched!.name, 'Potash Update');
      expect(refetched.initialStock, 95.5);

      await repo.delete('chem-t1');
      final deleted = await repo.getById('chem-t1');
      expect(deleted, isNull);
    });

    test('Chemical usage CRUD works correctly', () async {
      final repo = HiveFarmChemicalUsageRepository();
      final record = FarmFertilizerUsageModel(
        id: 'usage-t1',
        date: '2026-07-11',
        fertilizerId: 'chem-t1',
        bagsUsed: 1.25,
        createdDate: '2026-07-11',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-11',
        lastUpdatedTime: '12:00:00',
      );

      await repo.add(record);
      final fetched = await repo.getById('usage-t1');
      expect(fetched, isNotNull);
      expect(fetched!.bagsUsed, 1.25);

      await repo.delete('usage-t1');
      final deleted = await repo.getById('usage-t1');
      expect(deleted, isNull);
    });

    test('Organic inventory CRUD works correctly', () async {
      final repo = HiveFarmOrganicInventoryRepository();
      final record = FarmOrganicFertilizerModel(
        id: 'org-t1',
        date: '2026-07-11',
        name: 'Compost',
        loads: 15.0,
        unit: 'Pickup',
        price: 4500.0,
        totalPrice: 4500.0,
        createdDate: '2026-07-11',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-11',
        lastUpdatedTime: '12:00:00',
      );

      await repo.add(record);
      final fetched = await repo.getById('org-t1');
      expect(fetched, isNotNull);
      expect(fetched!.unit, 'Pickup');

      await repo.delete('org-t1');
      final deleted = await repo.getById('org-t1');
      expect(deleted, isNull);
    });
  });
}
