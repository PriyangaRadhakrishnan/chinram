import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/models/attendance_model.dart';
import 'package:chinram_app/features/estate/repositories/hive_attendance_repository.dart';

void main() {
  group('Attendance Model Unit Tests (ERP Audit Metadata)', () {
    test('WorkerAttendanceModel converts to and from JSON', () {
      const item = WorkerAttendanceModel(
        workerId: 'worker-1',
        status: AttendanceStatus.absent,
      );

      final json = item.toJson();
      expect(json['workerId'], 'worker-1');
      expect(json['status'], 'absent');

      final fromJson = WorkerAttendanceModel.fromJson(json);
      expect(fromJson.workerId, 'worker-1');
      expect(fromJson.status, AttendanceStatus.absent);
    });

    test('AttendanceModel serialization and calculations work correctly with Audit Logs', () {
      const model = AttendanceModel(
        date: '2026-07-03',
        records: [
          WorkerAttendanceModel(workerId: '1', status: AttendanceStatus.present),
          WorkerAttendanceModel(workerId: '2', status: AttendanceStatus.absent),
          WorkerAttendanceModel(workerId: '3', status: AttendanceStatus.present),
        ],
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '13:30:00',
      );

      expect(model.totalWorkers, 3);
      expect(model.presentCount, 2);
      expect(model.absentCount, 1);
      expect(model.createdDate, '2026-07-03');
      expect(model.createdTime, '12:00:00');
      expect(model.lastUpdatedDate, '2026-07-03');
      expect(model.lastUpdatedTime, '13:30:00');

      final json = model.toJson();
      expect(json['date'], '2026-07-03');
      expect(json['createdDate'], '2026-07-03');
      expect(json['createdTime'], '12:00:00');
      expect(json['lastUpdatedDate'], '2026-07-03');
      expect(json['lastUpdatedTime'], '13:30:00');

      final fromJson = AttendanceModel.fromJson(json);
      expect(fromJson.date, '2026-07-03');
      expect(fromJson.totalWorkers, 3);
      expect(fromJson.presentCount, 2);
      expect(fromJson.absentCount, 1);
      expect(fromJson.createdDate, '2026-07-03');
      expect(fromJson.createdTime, '12:00:00');
      expect(fromJson.lastUpdatedDate, '2026-07-03');
      expect(fromJson.lastUpdatedTime, '13:30:00');
    });

    test('AttendanceModel JSON backward-compatibility handles legacy nulls safely', () {
      final legacyJson = {
        'date': '2026-07-03',
        'records': [
          {'workerId': '1', 'status': 'present'},
        ]
      };

      final parsed = AttendanceModel.fromJson(legacyJson);
      expect(parsed.date, '2026-07-03');
      expect(parsed.createdDate, '2026-07-03'); // Fallbacks to date
      expect(parsed.createdTime, '00:00:00');
      expect(parsed.lastUpdatedDate, '2026-07-03'); // Fallbacks to date
      expect(parsed.lastUpdatedTime, '00:00:00');
    });
  });

  group('HiveAttendanceRepository Unit Tests with Audit Data', () {
    late Directory tempDir;
    late HiveAttendanceRepository repo;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_attendance_tests_erp');
      Hive.init(tempDir.path);
    });

    setUp(() {
      repo = HiveAttendanceRepository();
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('starts with empty history', () async {
      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    test('saves, retrieves, updates, and deletes records with metadata', () async {
      const record = AttendanceModel(
        date: '2026-07-03',
        records: [
          WorkerAttendanceModel(workerId: 'w1', status: AttendanceStatus.present),
        ],
        createdDate: '2026-07-03',
        createdTime: '10:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '10:00:00',
      );

      // Save
      await repo.save(record);

      // Get
      final retrieved = await repo.getByDate('2026-07-03');
      expect(retrieved, isNotNull);
      expect(retrieved!.date, '2026-07-03');
      expect(retrieved.records.first.workerId, 'w1');
      expect(retrieved.createdTime, '10:00:00');
      expect(retrieved.lastUpdatedTime, '10:00:00');

      // Update
      const updated = AttendanceModel(
        date: '2026-07-03',
        records: [
          WorkerAttendanceModel(workerId: 'w1', status: AttendanceStatus.absent),
          WorkerAttendanceModel(workerId: 'w2', status: AttendanceStatus.present),
        ],
        createdDate: '2026-07-03',
        createdTime: '10:00:00', // Unchanged
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '10:30:00', // Modified
      );
      await repo.save(updated);

      final retrievedUpdated = await repo.getByDate('2026-07-03');
      expect(retrievedUpdated!.records.length, 2);
      expect(retrievedUpdated.absentCount, 1);
      expect(retrievedUpdated.presentCount, 1);
      expect(retrievedUpdated.createdTime, '10:00:00');
      expect(retrievedUpdated.lastUpdatedTime, '10:30:00');

      // Delete
      await repo.delete('2026-07-03');
      final retrievedAfterDelete = await repo.getByDate('2026-07-03');
      expect(retrievedAfterDelete, isNull);
    });
  });
}
