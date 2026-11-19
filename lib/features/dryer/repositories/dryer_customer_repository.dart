import '../models/dryer_customer_model.dart';

abstract class DryerCustomerRepository {
  Future<List<DryerCustomer>> getAll();
  Future<DryerCustomer?> getById(String id);
  Future<DryerCustomer?> getByPhoneNumber(String phoneNumber);
  Future<void> add(DryerCustomer customer);
  Future<void> update(DryerCustomer customer);
  Future<void> delete(String id);
}
