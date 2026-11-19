import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/estate_repository.dart';
import '../repositories/mock_estate_repository.dart';
import '../models/estate_dashboard_data.dart';

final estateRepositoryProvider = Provider<EstateRepository>((ref) {
  return const MockEstateRepository();
});

final estateDashboardDataProvider = FutureProvider<EstateDashboardData>((ref) async {
  final repository = ref.watch(estateRepositoryProvider);
  return repository.getDashboardData();
});
