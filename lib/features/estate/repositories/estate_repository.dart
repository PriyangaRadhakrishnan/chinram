import '../models/estate_dashboard_data.dart';

abstract class EstateRepository {
  Future<EstateDashboardData> getDashboardData();
}
