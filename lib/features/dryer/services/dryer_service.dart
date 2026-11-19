import '../models/dryer_customer_model.dart';
import '../models/dryer_customer_summary.dart';
import '../models/dryer_visit_model.dart';
import '../repositories/dryer_customer_repository.dart';
import '../repositories/dryer_visit_repository.dart';
import '../utils/dryer_calculator.dart';

class DryerSaveResult {
  final DryerCustomer customer;
  final DryerVisit visit;
  final bool isNewCustomer;

  const DryerSaveResult({
    required this.customer,
    required this.visit,
    required this.isNewCustomer,
  });
}

class DryerService {
  final DryerCustomerRepository _customerRepository;
  final DryerVisitRepository _visitRepository;

  static int _idSequence = 0;

  const DryerService(
    this._customerRepository,
    this._visitRepository,
  );

  String _generateId(String prefix) {
    _idSequence++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  Future<List<DryerCustomerSummary>> getCustomerSummaries() async {
    final results = await Future.wait([
      _customerRepository.getAll(),
      _visitRepository.getAll(),
    ]);
    final customers = results[0] as List<DryerCustomer>;
    final visits = results[1] as List<DryerVisit>;

    final Map<String, List<DryerVisit>> visitsByCustomer = {};
    for (final visit in visits) {
      visitsByCustomer.putIfAbsent(visit.customerId, () => []).add(visit);
    }

    final summaries = customers.map((customer) {
      final customerVisits = visitsByCustomer[customer.id] ?? <DryerVisit>[];
      customerVisits.sort(DryerVisit.compareNewestFirst);
      return DryerCustomerSummary(
        customer: customer,
        visits: List<DryerVisit>.unmodifiable(customerVisits),
      );
    }).toList();

    summaries.sort((a, b) {
      final aLatest = a.latestVisit;
      final bLatest = b.latestVisit;
      if (aLatest != null && bLatest != null) {
        return DryerVisit.compareNewestFirst(aLatest, bLatest);
      }
      if (aLatest != null && bLatest == null) return -1;
      if (aLatest == null && bLatest != null) return 1;
      return b.customer.updatedAt.compareTo(a.customer.updatedAt);
    });

    return summaries;
  }

  Future<DryerCustomerSummary?> getCustomerSummaryById(
    String customerId,
  ) async {
    final customer = await _customerRepository.getById(customerId);
    if (customer == null) return null;
    final visits = await _visitRepository.getByCustomerId(customerId);
    visits.sort(DryerVisit.compareNewestFirst);
    return DryerCustomerSummary(
      customer: customer,
      visits: List<DryerVisit>.unmodifiable(visits),
    );
  }

  Future<List<DryerCustomer>> getAllCustomers() {
    return _customerRepository.getAll();
  }

  Future<DryerCustomer?> getCustomerById(String customerId) {
    return _customerRepository.getById(customerId);
  }

  Future<DryerCustomer?> findCustomerByPhone(String phoneNumber) {
    return _customerRepository.getByPhoneNumber(phoneNumber);
  }

  Future<List<DryerCustomer>> searchCustomersByPhone(String query) async {
    final normalizedQuery = DryerCalculator.normalizePhoneNumber(query);
    if (normalizedQuery.isEmpty) return const [];
    final customers = await _customerRepository.getAll();
    return customers.where((customer) {
      final normalizedCustomerPhone =
          DryerCalculator.normalizePhoneNumber(customer.phoneNumber);
      return normalizedCustomerPhone.contains(normalizedQuery) ||
          customer.phoneNumber.toLowerCase().contains(query.trim().toLowerCase());
    }).toList();
  }

  Future<DryerVisit?> getVisitById(String visitId) {
    return _visitRepository.getById(visitId);
  }

  Future<List<DryerVisit>> getVisitsForCustomer(String customerId) {
    return _visitRepository.getByCustomerId(customerId);
  }

  void _validateCustomerFields({
    required String name,
    required String phoneNumber,
    required String address,
    required double areaValue,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Customer name is required');
    }
    final phoneError = DryerCalculator.validatePhoneNumber(phoneNumber);
    if (phoneError != null) {
      throw ArgumentError(phoneError);
    }
    if (address.trim().isEmpty) {
      throw ArgumentError('Address is required');
    }
    if (!areaValue.isFinite || areaValue <= 0) {
      throw ArgumentError('Area value must be greater than zero');
    }
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
    final trimmedName = name.trim();
    final trimmedPhone = phoneNumber.trim();
    final trimmedAddress = address.trim();

    _validateCustomerFields(
      name: trimmedName,
      phoneNumber: trimmedPhone,
      address: trimmedAddress,
      areaValue: areaValue,
    );

    final percentage =
        DryerCalculator.calculatePercentage(greenQuantity, dryQuantity);
    final charges = DryerCalculator.calculateCharges(greenQuantity, rate);

    final now = DateTime.now();
    final existingByPhone =
        await _customerRepository.getByPhoneNumber(trimmedPhone);

    DryerCustomer targetCustomer;
    var createdNewCustomer = false;

    if (existingCustomerId != null) {
      final selectedCustomer =
          await _customerRepository.getById(existingCustomerId);
      if (selectedCustomer == null) {
        throw StateError('Selected customer could not be found');
      }
      if (existingByPhone != null && existingByPhone.id != selectedCustomer.id) {
        throw StateError(
          'Another customer (${existingByPhone.name}) already uses this phone number',
        );
      }

      final hasProfileChanged = selectedCustomer.name != trimmedName ||
          selectedCustomer.phoneNumber != trimmedPhone ||
          selectedCustomer.address != trimmedAddress ||
          selectedCustomer.areaType != areaType ||
          selectedCustomer.areaValue != areaValue;

      if (hasProfileChanged) {
        targetCustomer = selectedCustomer.copyWith(
          name: trimmedName,
          phoneNumber: trimmedPhone,
          address: trimmedAddress,
          areaType: areaType,
          areaValue: areaValue,
          updatedAt: now,
        );
        await _customerRepository.update(targetCustomer);
      } else {
        targetCustomer = selectedCustomer;
      }
    } else if (existingByPhone != null) {
      final hasProfileChanged = existingByPhone.name != trimmedName ||
          existingByPhone.phoneNumber != trimmedPhone ||
          existingByPhone.address != trimmedAddress ||
          existingByPhone.areaType != areaType ||
          existingByPhone.areaValue != areaValue;

      if (hasProfileChanged) {
        targetCustomer = existingByPhone.copyWith(
          name: trimmedName,
          phoneNumber: trimmedPhone,
          address: trimmedAddress,
          areaType: areaType,
          areaValue: areaValue,
          updatedAt: now,
        );
        await _customerRepository.update(targetCustomer);
      } else {
        targetCustomer = existingByPhone;
      }
    } else {
      targetCustomer = DryerCustomer(
        id: _generateId('cust'),
        name: trimmedName,
        phoneNumber: trimmedPhone,
        address: trimmedAddress,
        areaType: areaType,
        areaValue: areaValue,
        createdAt: now,
        updatedAt: now,
      );
      await _customerRepository.add(targetCustomer);
      createdNewCustomer = true;
    }

    final visit = DryerVisit(
      id: _generateId('visit'),
      customerId: targetCustomer.id,
      date: visitDate,
      greenQuantity: greenQuantity,
      product: product,
      dryQuantity: dryQuantity,
      percentage: percentage,
      rate: rate,
      charges: charges,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _visitRepository.add(visit);
    } catch (_) {
      if (createdNewCustomer) {
        try {
          await _customerRepository.delete(targetCustomer.id);
        } catch (_) {}
      }
      rethrow;
    }

    return DryerSaveResult(
      customer: targetCustomer,
      visit: visit,
      isNewCustomer: createdNewCustomer,
    );
  }

  Future<DryerCustomer> updateCustomer(DryerCustomer customer) async {
    final trimmedName = customer.name.trim();
    final trimmedPhone = customer.phoneNumber.trim();
    final trimmedAddress = customer.address.trim();

    _validateCustomerFields(
      name: trimmedName,
      phoneNumber: trimmedPhone,
      address: trimmedAddress,
      areaValue: customer.areaValue,
    );

    final existingByPhone =
        await _customerRepository.getByPhoneNumber(trimmedPhone);
    if (existingByPhone != null && existingByPhone.id != customer.id) {
      throw StateError(
        'Another customer (${existingByPhone.name}) already uses this phone number',
      );
    }

    final updated = customer.copyWith(
      name: trimmedName,
      phoneNumber: trimmedPhone,
      address: trimmedAddress,
      updatedAt: DateTime.now(),
    );
    await _customerRepository.update(updated);
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
    final percentage =
        DryerCalculator.calculatePercentage(greenQuantity, dryQuantity);
    final charges = DryerCalculator.calculateCharges(greenQuantity, rate);

    final updated = existingVisit.copyWith(
      date: date,
      greenQuantity: greenQuantity,
      product: product,
      dryQuantity: dryQuantity,
      percentage: percentage,
      rate: rate,
      charges: charges,
      updatedAt: DateTime.now(),
    );
    await _visitRepository.update(updated);
    return updated;
  }

  Future<void> deleteVisit(String visitId) async {
    await _visitRepository.delete(visitId);
  }

  Future<void> deleteCustomer(String customerId) async {
    await _visitRepository.deleteByCustomerId(customerId);
    await _customerRepository.delete(customerId);
  }
}
