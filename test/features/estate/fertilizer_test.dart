import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/fertilizer_model.dart';
import 'package:chinram_app/features/estate/models/fertilizer_usage_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_fertilizer_repository.dart';
import 'package:chinram_app/features/estate/services/fertilizer_service.dart';

void main() {
  group('Fertilizer Models Unit Tests', () {
    test('FertilizerModel converts to and from JSON', () {
      final model = FertilizerModel(
        id: 'fert-1',
        date: '2026-07-01',
        name: 'Urea',
        quantityPerBag: 50.0,
        unit: 'Kg',
        initialStock: 100,
        price: 5000.0,
        totalPrice: 5000.0,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = model.toJson();
      expect(json['id'], 'fert-1');
      expect(json['name'], 'Urea');
      expect(json['totalPrice'], 5000.0);

      final fromJson = FertilizerModel.fromJson(json);
      expect(fromJson.id, 'fert-1');
      expect(fromJson.initialStock, 100);
      expect(fromJson.totalPrice, 5000.0);
    });

    test('FertilizerUsageModel converts to and from JSON', () {
      final model = FertilizerUsageModel(
        id: 'use-1',
        date: '2026-07-02',
        fertilizerId: 'fert-1',
        bagsUsed: 5.5,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = model.toJson();
      expect(json['id'], 'use-1');
      expect(json['bagsUsed'], 5.5);

      final fromJson = FertilizerUsageModel.fromJson(json);
      expect(fromJson.id, 'use-1');
      expect(fromJson.bagsUsed, 5.5);
    });
  });

  group('HiveFertilizerRepository and Service Unit Tests', () {
    late Directory tempDir;
    late HiveFertilizerRepository repo;
    late FertilizerService service;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_fertilizer_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repo = HiveFertilizerRepository();
      service = FertilizerService(repo);
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves fertilizer and generates a positive ledger purchase transaction', () async {
      final fert = FertilizerModel(
        id: 'f-test-1',
        date: '2026-07-01',
        name: 'Potash',
        quantityPerBag: 50.0,
        unit: 'Kg',
        initialStock: 10,
        price: 3000.0,
        totalPrice: 3000.0,
        createdDate: '2026-07-03',
        createdTime: '10:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '10:00:00',
      );

      await service.saveFertilizer(fert, 10);

      // Verify stock calculated dynamically is 10
      final stock = await service.getStockForFertilizer('f-test-1');
      expect(stock, 10.0);

      final txs = await service.getTransactions();
      expect(txs.length, 1);
      expect(txs.first.type, 'purchase');
      expect(txs.first.quantity, 10.0);
    });

    test('saves usage and updates stock ledger transaction correctly', () async {
      final usage = FertilizerUsageModel(
        id: 'u-test-1',
        date: '2026-07-02',
        fertilizerId: 'f-test-1',
        bagsUsed: 3.5,
        createdDate: '2026-07-03',
        createdTime: '11:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '11:00:00',
      );

      await service.saveUsage(usage);

      // Calculated stock should be 10 - 3.5 = 6.5
      final stock = await service.getStockForFertilizer('f-test-1');
      expect(stock, 6.5);

      final txs = await service.getTransactions();
      expect(txs.length, 2);
      expect(txs.where((t) => t.type == 'usage').first.quantity, -3.5);
    });

    test('deleting fertilizer deletes associated ledger transactions and usages', () async {
      await service.deleteFertilizer('f-test-1');

      final remainingFerts = await service.getFertilizers();
      expect(remainingFerts.where((f) => f.id == 'f-test-1'), isEmpty);

      final remainingUsages = await service.getUsages();
      expect(remainingUsages.where((u) => u.fertilizerId == 'f-test-1'), isEmpty);

      final remainingTxs = await service.getTransactions();
      expect(remainingTxs.where((t) => t.fertilizerId == 'f-test-1'), isEmpty);
    });
  });
}
