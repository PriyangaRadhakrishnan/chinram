import 'package:hive/hive.dart';
import '../models/dryer_visit_model.dart';
import 'dryer_visit_repository.dart';

class HiveDryerVisitRepository implements DryerVisitRepository {
  static const String boxName = 'dryer_visits_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(boxName);
  }

  @override
  Future<List<DryerVisit>> getAll() async {
    final box = await _getBox();
    final List<DryerVisit> visits = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        visits.add(DryerVisit.fromJson(value));
      } else {
        throw FormatException('Invalid visit record format for key "$key"');
      }
    }
    visits.sort(DryerVisit.compareNewestFirst);
    return visits;
  }

  @override
  Future<List<DryerVisit>> getByCustomerId(String customerId) async {
    final allVisits = await getAll();
    final customerVisits = allVisits
        .where((visit) => visit.customerId == customerId)
        .toList();
    customerVisits.sort(DryerVisit.compareNewestFirst);
    return customerVisits;
  }

  @override
  Future<DryerVisit?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value == null) return null;
    if (value is Map) {
      return DryerVisit.fromJson(value);
    }
    throw FormatException('Invalid visit record format for id "$id"');
  }

  @override
  Future<void> add(DryerVisit visit) async {
    final box = await _getBox();
    await box.put(visit.id, visit.toJson());
  }

  @override
  Future<void> update(DryerVisit visit) async {
    final box = await _getBox();
    await box.put(visit.id, visit.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<void> deleteByCustomerId(String customerId) async {
    final box = await _getBox();
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['customerId'] == customerId) {
        keysToDelete.add(key);
      }
    }
    await box.deleteAll(keysToDelete);
  }
}
