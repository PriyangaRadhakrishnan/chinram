import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/organic_fertilizer_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_organic_fertilizer_repository.dart';

void main() {
  group('OrganicFertilizerModel Unit Tests', () {
    test('converts to and from JSON', () {
      final record = OrganicFertilizerModel(
        id: 'org-1',
        date: '2026-07-10',
        name: 'Chicken Manure',
        loads: 3.5,
        unit: 'Tractor',
        price: 15000.0,
        totalPrice: 15000.0,
        createdDate: '2026-07-10',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-10',
        lastUpdatedTime: '12:00:00',
      );

      final json = record.toJson();
      expect(json['id'], 'org-1');
      expect(json['name'], 'Chicken Manure');
      expect(json['loads'], 3.5);
      expect(json['unit'], 'Tractor');
      expect(json['price'], 15000.0);
      expect(json['totalPrice'], 15000.0);

      final fromJson = OrganicFertilizerModel.fromJson(json);
      expect(fromJson.id, 'org-1');
      expect(fromJson.date, '2026-07-10');
      expect(fromJson.name, 'Chicken Manure');
      expect(fromJson.loads, 3.5);
      expect(fromJson.unit, 'Tractor');
      expect(fromJson.price, 15000.0);
      expect(fromJson.totalPrice, 15000.0);
    });

    test('supports copyWith', () {
      final record = OrganicFertilizerModel(
        id: 'org-1',
        date: '2026-07-10',
        name: 'Cow Dung',
        loads: 2.0,
        unit: 'Pickup',
        price: 8000.0,
        totalPrice: 8000.0,
        createdDate: '2026-07-10',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-10',
        lastUpdatedTime: '12:00:00',
      );

      final updated = record.copyWith(
        loads: 4.0,
        price: 16000.0,
        totalPrice: 16000.0,
      );

      expect(updated.id, 'org-1');
      expect(updated.name, 'Cow Dung');
      expect(updated.loads, 4.0);
      expect(updated.price, 16000.0);
      expect(updated.totalPrice, 16000.0);
    });
  });

  group('HiveOrganicFertilizerRepository Unit Tests', () {
    late Directory tempDir;
    late HiveOrganicFertilizerRepository repo;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_organic_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repo = HiveOrganicFertilizerRepository();
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

    test('saves, retrieves, updates, and deletes organic fertilizer records in Hive', () async {
      final record = OrganicFertilizerModel(
        id: 'org-unique',
        date: '2026-07-10',
        name: 'Compost Bag',
        loads: 1.5,
        unit: '407',
        price: 4500.0,
        totalPrice: 4500.0,
        createdDate: '2026-07-10',
        createdTime: '15:00:00',
        lastUpdatedDate: '2026-07-10',
        lastUpdatedTime: '15:00:00',
      );

      // Save
      await repo.save(record);

      // Get All
      var all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'org-unique');
      expect(all.first.price, 4500.0);

      // Get by ID
      final retrieved = await repo.getById('org-unique');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Compost Bag');

      // Update
      final updated = record.copyWith(
        loads: 2.0,
        price: 6000.0,
        totalPrice: 6000.0,
      );
      await repo.save(updated);

      final retrievedUpdated = await repo.getById('org-unique');
      expect(retrievedUpdated!.loads, 2.0);
      expect(retrievedUpdated.price, 6000.0);

      // Delete
      await repo.delete('org-unique');
      all = await repo.getAll();
      expect(all, isEmpty);
    });
  });
}
