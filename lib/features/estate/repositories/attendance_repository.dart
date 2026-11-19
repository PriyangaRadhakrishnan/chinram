import '../models/attendance_model.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceModel>> getAll();
  Future<AttendanceModel?> getByDate(String date);
  Future<void> save(AttendanceModel attendance);
  Future<void> delete(String date);
}
