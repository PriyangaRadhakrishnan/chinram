import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';

class AttendanceService {
  final AttendanceRepository _repository;

  const AttendanceService(this._repository);

  Future<List<AttendanceModel>> getAll() => _repository.getAll();
  Future<AttendanceModel?> getByDate(String date) => _repository.getByDate(date);
  Future<void> save(AttendanceModel attendance) => _repository.save(attendance);
  Future<void> delete(String date) => _repository.delete(date);
}
