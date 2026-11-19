import 'package:hive/hive.dart';
import '../models/attendance_model.dart';
import 'attendance_repository.dart';

class HiveAttendanceRepository implements AttendanceRepository {
  static const String _boxName = 'attendance_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<AttendanceModel>> getAll() async {
    final box = await _getBox();
    final List<AttendanceModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(AttendanceModel.fromJson(value));
      }
    }
    // Sort by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<AttendanceModel?> getByDate(String date) async {
    final box = await _getBox();
    final value = box.get(date);
    if (value is Map) {
      return AttendanceModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> save(AttendanceModel attendance) async {
    final box = await _getBox();
    await box.put(attendance.date, attendance.toJson());
  }

  @override
  Future<void> delete(String date) async {
    final box = await _getBox();
    await box.delete(date);
  }
}
