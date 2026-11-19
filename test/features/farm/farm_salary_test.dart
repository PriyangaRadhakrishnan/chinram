import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/farm/models/farm_salary_model.dart';
import 'package:chinram_app/features/farm/repositories/hive_farm_salary_repository.dart';

void main() {
  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('FarmSalaryModel Unit Tests', () {
    test('converts farm salary model to and from JSON', () {
      final model = FarmSalaryModel(
        id: 'sal-1',
        fromDate: DateTime.parse('2026-07-06'),
        toDate: DateTime.parse('2026-07-12'),
        work: 'Weeding',
        numberOfPersons: 5,
        salaryAmount: 7500.00,
        notes: 'Cleared plot D',
        createdDate: '2026-07-12',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-12',
        lastUpdatedTime: '12:00:00',
      );

      final json = model.toJson();
      expect(json['id'], 'sal-1');
      expect(json['work'], 'Weeding');
      expect(json['numberOfPersons'], 5);
      expect(json['salaryAmount'], 7500.00);

      final fromJson = FarmSalaryModel.fromJson(json);
      expect(fromJson.id, 'sal-1');
      expect(fromJson.work, 'Weeding');
      expect(fromJson.numberOfPersons, 5);
      expect(fromJson.salaryAmount, 7500.0);
    });

    test('supports copyWith', () {
      final model = FarmSalaryModel(
        id: 'sal-1',
        fromDate: DateTime.parse('2026-07-06'),
        toDate: DateTime.parse('2026-07-12'),
        work: 'Weeding',
        numberOfPersons: 5,
        salaryAmount: 7500.00,
        createdDate: '2026-07-12',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-12',
        lastUpdatedTime: '12:00:00',
      );

      final updated = model.copyWith(salaryAmount: 8000.00, work: 'Harvesting');
      expect(updated.salaryAmount, 8000.00);
      expect(updated.work, 'Harvesting');
      expect(updated.numberOfPersons, 5);
    });
  });

  group('HiveFarmSalaryRepository Integration Tests', () {
    test('Farm salary CRUD works correctly', () async {
      final repo = HiveFarmSalaryRepository();
      final record = FarmSalaryModel(
        id: 'sal-t1',
        fromDate: DateTime.parse('2026-07-06'),
        toDate: DateTime.parse('2026-07-12'),
        work: 'Watering',
        numberOfPersons: 2,
        salaryAmount: 2000.00,
        createdDate: '2026-07-12',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-12',
        lastUpdatedTime: '12:00:00',
      );

      // Add & Get
      await repo.add(record);
      final fetched = await repo.getById('sal-t1');
      expect(fetched, isNotNull);
      expect(fetched!.work, 'Watering');
      expect(fetched.salaryAmount, 2000.00);

      // Update
      final updated = record.copyWith(salaryAmount: 2500.00);
      await repo.update(updated);
      final fetchedUpdated = await repo.getById('sal-t1');
      expect(fetchedUpdated!.salaryAmount, 2500.00);

      // Delete
      await repo.delete('sal-t1');
      final deleted = await repo.getById('sal-t1');
      expect(deleted, isNull);
    });
  });
}
