import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dryer_customer_model.dart';
import '../models/dryer_customer_summary.dart';
import '../models/dryer_visit_model.dart';
import '../repositories/dryer_customer_repository.dart';
import '../repositories/dryer_visit_repository.dart';
import '../repositories/hive_dryer_customer_repository.dart';
import '../repositories/hive_dryer_visit_repository.dart';
import '../services/dryer_service.dart';

final dryerCustomerRepositoryProvider =
    Provider<DryerCustomerRepository>((ref) {
  return HiveDryerCustomerRepository();
});

final dryerVisitRepositoryProvider = Provider<DryerVisitRepository>((ref) {
  return HiveDryerVisitRepository();
});

final dryerServiceProvider = Provider<DryerService>((ref) {
  final customerRepo = ref.watch(dryerCustomerRepositoryProvider);
  final visitRepo = ref.watch(dryerVisitRepositoryProvider);
  return DryerService(customerRepo, visitRepo);
});

class DryerCustomersNotifier
    extends AsyncNotifier<List<DryerCustomerSummary>> {
  DryerService get _service => ref.read(dryerServiceProvider);

  @override
  Future<List<DryerCustomerSummary>> build() async {
    final service = ref.watch(dryerServiceProvider);
    return service.getCustomerSummaries();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getCustomerSummaries());
  }

  Future<DryerSaveResult> saveCustomerAndVisit({
    String? existingCustomerId,
    required String name,
    required String phoneNumber,
    required String address,
    required DryerAreaType areaType,
    required double areaValue,
    required DateTime visitDate,
    required double greenQuantity,
    required DryerProduct product,
    required double dryQuantity,
    required double rate,
  }) async {
    final result = await _service.saveCustomerAndVisit(
      existingCustomerId: existingCustomerId,
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      areaType: areaType,
      areaValue: areaValue,
      visitDate: visitDate,
      greenQuantity: greenQuantity,
      product: product,
      dryQuantity: dryQuantity,
      rate: rate,
    );
    final updatedList = await _service.getCustomerSummaries();
    state = AsyncValue.data(updatedList);
    return result;
  }

  Future<DryerCustomer> updateCustomer(DryerCustomer customer) async {
    final updated = await _service.updateCustomer(customer);
    final updatedList = await _service.getCustomerSummaries();
    state = AsyncValue.data(updatedList);
    return updated;
  }

  Future<DryerVisit> updateVisit({
    required DryerVisit existingVisit,
    required DateTime date,
    required double greenQuantity,
    required DryerProduct product,
    required double dryQuantity,
    required double rate,
  }) async {
    final updated = await _service.updateVisit(
      existingVisit: existingVisit,
      date: date,
      greenQuantity: greenQuantity,
      product: product,
      dryQuantity: dryQuantity,
      rate: rate,
    );
    final updatedList = await _service.getCustomerSummaries();
    state = AsyncValue.data(updatedList);
    return updated;
  }

  Future<void> deleteVisit(String visitId) async {
    await _service.deleteVisit(visitId);
    final updatedList = await _service.getCustomerSummaries();
    state = AsyncValue.data(updatedList);
  }

  Future<void> deleteCustomer(String customerId) async {
    await _service.deleteCustomer(customerId);
    final updatedList = await _service.getCustomerSummaries();
    state = AsyncValue.data(updatedList);
  }
}

final dryerCustomersProvider = AsyncNotifierProvider<DryerCustomersNotifier,
    List<DryerCustomerSummary>>(() {
  return DryerCustomersNotifier();
});
