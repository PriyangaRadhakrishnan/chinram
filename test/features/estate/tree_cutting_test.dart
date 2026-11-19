import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/tree_cutting_model.dart';
import 'package:chinram_app/features/estate/models/tree_count_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_tree_cutting_repository.dart';
import 'package:chinram_app/features/estate/repositories/hive_tree_count_repository.dart';
import 'package:chinram_app/features/estate/services/tree_cutting_service.dart';
import 'package:chinram_app/features/estate/services/tree_count_service.dart';

void main() {
  group('TreeCuttingModel Unit Tests', () {
    test('converts to and from JSON', () {
      final record = TreeCuttingModel(
        id: 'tc-cut-1',
        date: '2026-07-02',
        treeName: 'Coffee',
        placeName: 'Area A',
        numberOfTrees: 20,
        pricePerTree: 2000.0,
        totalAmount: 40000.0,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = record.toJson();
      expect(json['id'], 'tc-cut-1');
      expect(json['numberOfTrees'], 20);
      expect(json['totalAmount'], 40000.0);

      final fromJson = TreeCuttingModel.fromJson(json);
      expect(fromJson.id, 'tc-cut-1');
      expect(fromJson.placeName, 'Area A');
      expect(fromJson.pricePerTree, 2000.0);
      expect(fromJson.totalAmount, 40000.0);
    });

    test('supports nullable values and backward compatibility with plotName', () {
      final legacyJson = {
        'id': 'tc-legacy',
        'date': '2026-07-02',
        'treeName': 'Coffee',
        'plotName': 'Plot B',
        'numberOfTrees': 10,
        'pricePerTree': 1000.0,
        'totalAmount': 10000.0,
        'createdDate': '2026-07-03',
        'createdTime': '12:00:00',
        'lastUpdatedDate': '2026-07-03',
        'lastUpdatedTime': '12:00:00',
      };

      final fromLegacy = TreeCuttingModel.fromJson(legacyJson);
      expect(fromLegacy.placeName, 'Plot B');

      final nullPricingModel = TreeCuttingModel(
        id: 'tc-nulls',
        date: '2026-07-02',
        totalAmount: 15000.0,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = nullPricingModel.toJson();
      expect(json['numberOfTrees'], isNull);
      expect(json['pricePerTree'], isNull);
      expect(json['totalAmount'], 15000.0);

      final fromJson = TreeCuttingModel.fromJson(json);
      expect(fromJson.numberOfTrees, isNull);
      expect(fromJson.pricePerTree, isNull);
      expect(fromJson.totalAmount, 15000.0);
    });
  });

  group('HiveTreeCuttingRepository and Service Unit Tests', () {
    late Directory tempDir;
    late HiveTreeCuttingRepository cuttingRepo;
    late HiveTreeCountRepository countRepo;
    late TreeCuttingService cuttingService;
    late TreeCountService countService;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_cutting_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      cuttingRepo = HiveTreeCuttingRepository();
      countRepo = HiveTreeCountRepository();
      cuttingService = TreeCuttingService(cuttingRepo);
      countService = TreeCountService(countRepo);
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves cutting log independently of tree counts inventory', () async {
      // 1. Setup Tree Count Inventory with 100 Trees
      final treeInventory = TreeCountModel(
        id: 'tc-inv-1',
        date: '2026-07-01',
        treeName: 'Pepper',
        plotName: 'Plot A',
        initialCount: 100,
        createdDate: '2026-07-03',
        createdTime: '10:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '10:00:00',
      );
      await countService.saveTreeCount(treeInventory, 100);

      // Verify current stock is 100
      var currentStock = await countService.getQuantityForTreeCount('tc-inv-1');
      expect(currentStock, 100);

      // 2. Perform Tree Cutting of 30 Trees (independent)
      final cuttingRecord = TreeCuttingModel(
        id: 'cut-test-1',
        date: '2026-07-02',
        treeName: 'Pepper',
        placeName: 'Area A',
        numberOfTrees: 30,
        pricePerTree: 1500.0,
        totalAmount: 45000.0,
        createdDate: '2026-07-03',
        createdTime: '11:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '11:00:00',
      );

      await cuttingService.saveTreeCutting(cuttingRecord);

      // 3. Verify stock is STILL 100 (unaffected)
      currentStock = await countService.getQuantityForTreeCount('tc-inv-1');
      expect(currentStock, 100);

      // Verify records are saved in cuttingRepo
      final cuttings = await cuttingService.getTreeCuttings();
      expect(cuttings.length, 1);
      expect(cuttings.first.placeName, 'Area A');
    });

    test('deleting cutting log deletes the record successfully', () async {
      await cuttingService.deleteTreeCutting('cut-test-1');

      // Verify record is deleted
      final cuttings = await cuttingService.getTreeCuttings();
      expect(cuttings, isEmpty);

      // Verify stock is still 100
      final currentStock = await countService.getQuantityForTreeCount('tc-inv-1');
      expect(currentStock, 100);
    });
  });
}
