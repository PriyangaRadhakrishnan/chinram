import '../models/dryer_visit_model.dart';

abstract class DryerVisitRepository {
  Future<List<DryerVisit>> getAll();
  Future<List<DryerVisit>> getByCustomerId(String customerId);
  Future<DryerVisit?> getById(String id);
  Future<void> add(DryerVisit visit);
  Future<void> update(DryerVisit visit);
  Future<void> delete(String id);
  Future<void> deleteByCustomerId(String customerId);
}
