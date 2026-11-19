import 'package:hive/hive.dart';
import '../models/worker_model.dart';
import 'worker_repository.dart';

class HiveWorkerRepository implements WorkerRepository {
  static const String _boxName = 'workers_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  @override
  Future<List<WorkerModel>> getAll() async {
    final box = await _getBox();
    final List<WorkerModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(WorkerModel.fromJson(value));
      }
    }
    return list;
  }

  @override
  Future<WorkerModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return WorkerModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> add(WorkerModel worker) async {
    final box = await _getBox();
    await box.put(worker.id, worker.toJson());
  }

  @override
  Future<void> update(WorkerModel worker) async {
    final box = await _getBox();
    await box.put(worker.id, worker.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
