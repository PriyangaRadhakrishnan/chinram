import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/tree_count_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_tree_count_repository.dart';
import 'package:chinram_app/features/estate/services/tree_count_service.dart';

void main() {
  group('TreeCountModel Unit Tests', () {
    test('converts to and from JSON', () {
      final record = TreeCountModel(
        id: 'tc-1',
        date: '2026-07-01',
        treeName: 'Coffee',
        plotName: 'Plot A',
        initialCount: 350,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = record.toJson();
      expect(json['id'], 'tc-1');
      expect(json['treeName'], 'Coffee');
      expect(json['initialCount'], 350);

      final fromJson = TreeCountModel.fromJson(json);
      expect(fromJson.id, 'tc-1');
      expect(fromJson.plotName, 'Plot A');
      expect(fromJson.initialCount, 350);
    });
  });

  group('HiveTreeCountRepository and Service Unit Tests', () {
    late Directory tempDir;
    late HiveTreeCountRepository repo;
    late TreeCountService service;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_tree_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repo = HiveTreeCountRepository();
      service = TreeCountService(repo);
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves record and generates initial ledger transaction', () async {
      final record = TreeCountModel(
        id: 'tc-test-1',
        date: '2026-07-01',
        treeName: 'Jackfruit',
        plotName: 'Plot B',
        initialCount: 50,
        createdDate: '2026-07-03',
        createdTime: '10:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '10:00:00',
      );

      await service.saveTreeCount(record, 50);

      // Verify dynamic count calculations
      final count = await service.getQuantityForTreeCount('tc-test-1');
      expect(count, 50);

      final txs = await service.getLedgerTransactions();
      expect(txs.length, 1);
      expect(txs.first.type, 'initial_count');
      expect(txs.first.quantity, 50);
    });

    test('deleting record removes ledger transactions', () async {
      await service.deleteTreeCount('tc-test-1');

      final remainingRecords = await service.getTreeCounts();
      expect(remainingRecords.where((r) => r.id == 'tc-test-1'), isEmpty);

      final remainingTxs = await service.getLedgerTransactions();
      expect(remainingTxs.where((t) => t.treeCountId == 'tc-test-1'), isEmpty);
    });
  });
}
