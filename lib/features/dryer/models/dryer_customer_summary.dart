import 'dryer_customer_model.dart';
import 'dryer_visit_model.dart';

class DryerCustomerSummary {
  final DryerCustomer customer;
  final List<DryerVisit> visits;

  const DryerCustomerSummary({
    required this.customer,
    required this.visits,
  });

  DryerVisit? get latestVisit => visits.isNotEmpty ? visits.first : null;

  int get visitCount => visits.length;
}
