import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/manager_salary_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_manager_salary_repository.dart';
import 'package:chinram_app/features/estate/services/manager_salary_service.dart';

void main() {
  group('ManagerSalaryModel Unit Tests', () {
    test('converts to and from JSON', () {
      final record = ManagerSalaryModel(
        id: 'ms-test-1',
        fromDate: '2026-07-01',
        toDate: '2026-07-08',
        weeklySalary: 6000.0,
        createdDate: '2026-07-09',
        createdTime: '10:00:00',
        lastUpdatedDate: '2026-07-09',
        lastUpdatedTime: '10:00:00',
      );

      final json = record.toJson();
      expect(json['id'], 'ms-test-1');
      expect(json['weeklySalary'], 6000.0);

      final fromJson = ManagerSalaryModel.fromJson(json);
      expect(fromJson.id, 'ms-test-1');
      expect(fromJson.fromDate, '2026-07-01');
      expect(fromJson.toDate, '2026-07-08');
      expect(fromJson.weeklySalary, 6000.0);
    });

    test('supports copyWith', () {
      final record = ManagerSalaryModel(
        id: 'ms-test-2',
        fromDate: '2026-07-01',
        toDate: '2026-07-08',
        weeklySalary: 5000.0,
        createdDate: '2026-07-09',
        createdTime: '10:00:00',
        lastUpdatedDate: '2026-07-09',
        lastUpdatedTime: '10:00:00',
      );

      final updated = record.copyWith(weeklySalary: 5500.0);
      expect(updated.weeklySalary, 5500.0);
      expect(updated.id, 'ms-test-2');
    });
  });

  group('HiveManagerSalaryRepository and Service Integration Tests', () {
    late Directory tempDir;
    late HiveManagerSalaryRepository repository;
    late ManagerSalaryService service;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_manager_salary_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repository = HiveManagerSalaryRepository();
      service = ManagerSalaryService(repository);
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves, retrieves, updates, and deletes manager told salary records', () async {
      // 1. Initially empty
      var list = await service.getAll();
      expect(list, isEmpty);

      // 2. Save a record
      final record = ManagerSalaryModel(
        id: 'ms-crud-1',
        fromDate: '2026-07-01',
        toDate: '2026-07-08',
        weeklySalary: 7500.0,
        createdDate: '2026-07-09',
        createdTime: '11:00:00',
        lastUpdatedDate: '2026-07-09',
        lastUpdatedTime: '11:00:00',
      );
      await service.save(record);

      // Verify retrieval
      list = await service.getAll();
      expect(list.length, 1);
      expect(list.first.id, 'ms-crud-1');
      expect(list.first.weeklySalary, 7500.0);

      // 3. Update record
      final updatedRecord = record.copyWith(weeklySalary: 8000.0);
      await service.save(updatedRecord);

      // Verify update
      final retrieved = await service.getById('ms-crud-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.weeklySalary, 8000.0);

      // 4. Delete record
      await service.delete('ms-crud-1');

      // Verify deletion
      list = await service.getAll();
      expect(list, isEmpty);
    });
  });
}
