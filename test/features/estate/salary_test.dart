import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/salary_model.dart';
import 'package:chinram_app/features/estate/models/salary_configuration_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_salary_repository.dart';

void main() {
  group('Salary Configuration Model Unit Tests', () {
    test('converts to and from JSON', () {
      const config = SalaryConfigurationModel(
        maleDailyWage: 850.0,
        femaleDailyWage: 750.0,
      );

      final json = config.toJson();
      expect(json['maleDailyWage'], 850.0);
      expect(json['femaleDailyWage'], 750.0);

      final fromJson = SalaryConfigurationModel.fromJson(json);
      expect(fromJson.maleDailyWage, 850.0);
      expect(fromJson.femaleDailyWage, 750.0);
    });

    test('fromJson handles nulls with defaults', () {
      final fromJson = SalaryConfigurationModel.fromJson({});
      expect(fromJson.maleDailyWage, 800.0);
      expect(fromJson.femaleDailyWage, 700.0);
    });
  });

  group('Salary Model Unit Tests', () {
    test('converts to and from JSON with all audit logs', () {
      final salary = SalaryModel(
        id: 'sal-1',
        workerId: 'w-1',
        period: 'July 2026',
        startDate: '2026-07-01',
        endDate: '2026-07-03',
        calculationMethod: 'manual',
        durationUnit: 'days',
        durationValue: 3,
        presentDays: 0,
        dailyWage: 800.0,
        totalSalary: 2400.0,
        paymentStatus: 'pending',
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      );

      final json = salary.toJson();
      expect(json['id'], 'sal-1');
      expect(json['totalSalary'], 2400.0);
      expect(json['paymentStatus'], 'pending');

      final fromJson = SalaryModel.fromJson(json);
      expect(fromJson.id, 'sal-1');
      expect(fromJson.workerId, 'w-1');
      expect(fromJson.period, 'July 2026');
      expect(fromJson.totalSalary, 2400.0);
      expect(fromJson.paymentStatus, 'pending');
      expect(fromJson.createdDate, '2026-07-03');
      expect(fromJson.lastUpdatedTime, '12:00:00');
    });
  });

  group('HiveSalaryRepository Unit Tests', () {
    late Directory tempDir;
    late HiveSalaryRepository repo;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_salary_tests');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repo = HiveSalaryRepository();
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loads default configuration if none exists', () async {
      final config = await repo.getConfiguration();
      expect(config.maleDailyWage, 800.0);
      expect(config.femaleDailyWage, 700.0);
    });

    test('saves and retrieves custom configuration settings', () async {
      const customConfig = SalaryConfigurationModel(maleDailyWage: 900.0, femaleDailyWage: 800.0);
      await repo.saveConfiguration(customConfig);

      final retrieved = await repo.getConfiguration();
      expect(retrieved.maleDailyWage, 900.0);
      expect(retrieved.femaleDailyWage, 800.0);
    });

    test('saves, retrieves, updates, and deletes salary records', () async {
      final salary = SalaryModel(
        id: 'sal-unique',
        workerId: 'w-tapper',
        period: 'July 2026',
        startDate: '2026-07-01',
        endDate: '2026-07-30',
        calculationMethod: 'attendance',
        durationUnit: 'days',
        durationValue: 0,
        presentDays: 20,
        dailyWage: 800.0,
        totalSalary: 16000.0,
        paymentStatus: 'pending',
        createdDate: '2026-07-03',
        createdTime: '15:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '15:00:00',
      );

      // Save
      await repo.save(salary);

      // Get All
      var all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'sal-unique');
      expect(all.first.totalSalary, 16000.0);

      // Get by ID
      final retrieved = await repo.getById('sal-unique');
      expect(retrieved, isNotNull);
      expect(retrieved!.presentDays, 20);

      // Update
      final updated = salary.copyWith(
        paymentStatus: 'paid',
        paymentDate: '2026-07-03',
        paymentTime: '16:00:00',
        lastUpdatedTime: '16:00:00',
      );
      await repo.save(updated);

      final retrievedUpdated = await repo.getById('sal-unique');
      expect(retrievedUpdated!.paymentStatus, 'paid');
      expect(retrievedUpdated.paymentTime, '16:00:00');

      // Delete
      await repo.delete('sal-unique');
      all = await repo.getAll();
      expect(all, isEmpty);
    });
  });
}
