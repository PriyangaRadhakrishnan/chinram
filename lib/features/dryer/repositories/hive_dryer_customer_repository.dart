import 'package:hive/hive.dart';
import '../models/dryer_customer_model.dart';
import '../utils/dryer_calculator.dart';
import 'dryer_customer_repository.dart';

class HiveDryerCustomerRepository implements DryerCustomerRepository {
  static const String boxName = 'dryer_customers_box';

  Future<Box> _getBox() async {
    return await Hive.openBox(boxName);
  }

  @override
  Future<List<DryerCustomer>> getAll() async {
    final box = await _getBox();
    final List<DryerCustomer> customers = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        customers.add(DryerCustomer.fromJson(value));
      } else {
        throw FormatException('Invalid customer record format for key "$key"');
      }
    }
    customers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return customers;
  }

  @override
  Future<DryerCustomer?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value == null) return null;
    if (value is Map) {
      return DryerCustomer.fromJson(value);
    }
    throw FormatException('Invalid customer record format for id "$id"');
  }

  @override
  Future<DryerCustomer?> getByPhoneNumber(String phoneNumber) async {
    final targetNormalized = DryerCalculator.normalizePhoneNumber(phoneNumber);
    if (targetNormalized.isEmpty) return null;
    final customers = await getAll();
    for (final customer in customers) {
      if (DryerCalculator.normalizePhoneNumber(customer.phoneNumber) ==
          targetNormalized) {
        return customer;
      }
    }
    return null;
  }

  @override
  Future<void> add(DryerCustomer customer) async {
    final box = await _getBox();
    await box.put(customer.id, customer.toJson());
  }

  @override
  Future<void> update(DryerCustomer customer) async {
    final box = await _getBox();
    await box.put(customer.id, customer.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
