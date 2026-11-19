import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salary_model.dart';
import '../models/salary_configuration_model.dart';
import '../repositories/salary_repository.dart';
import '../repositories/hive_salary_repository.dart';
import '../services/salary_service.dart';

final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  return HiveSalaryRepository();
});

final salaryServiceProvider = Provider<SalaryService>((ref) {
  final repository = ref.watch(salaryRepositoryProvider);
  return SalaryService(repository);
});

// Manage daily logs of workers' salaries
class SalaryListNotifier extends AsyncNotifier<List<SalaryModel>> {
  late final SalaryService _service;

  @override
  Future<List<SalaryModel>> build() async {
    _service = ref.watch(salaryServiceProvider);
    return _service.getAll();
  }

  Future<void> addSalary(SalaryModel salary) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(salary);
      return _service.getAll();
    });
  }

  Future<void> updateSalary(SalaryModel salary) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(salary);
      return _service.getAll();
    });
  }

  Future<void> deleteSalary(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final salaryListProvider = AsyncNotifierProvider<SalaryListNotifier, List<SalaryModel>>(() {
  return SalaryListNotifier();
});

// Manage Male & Female daily wages configurations
class SalaryConfigNotifier extends AsyncNotifier<SalaryConfigurationModel> {
  late final SalaryService _service;

  @override
  Future<SalaryConfigurationModel> build() async {
    _service = ref.watch(salaryServiceProvider);
    return _service.getConfiguration();
  }

  Future<void> saveConfiguration(SalaryConfigurationModel config) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveConfiguration(config);
      return _service.getConfiguration();
    });
  }
}

final salaryConfigProvider = AsyncNotifierProvider<SalaryConfigNotifier, SalaryConfigurationModel>(() {
  return SalaryConfigNotifier();
});

// Group summaries for salary periods
class SalaryPeriodSummary {
  final String period;
  final String generatedDate;
  final int totalWorkers;
  final double totalSalary;
  final int paidCount;
  final int pendingCount;
  final double paidAmount;
  final double pendingAmount;
  final String lastUpdated;

  const SalaryPeriodSummary({
    required this.period,
    required this.generatedDate,
    required this.totalWorkers,
    required this.totalSalary,
    required this.paidCount,
    required this.pendingCount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.lastUpdated,
  });
}

// Selector provider returning grouped summaries reactive to salary changes
final salaryPeriodSummariesProvider = Provider<AsyncValue<List<SalaryPeriodSummary>>>((ref) {
  final salariesAsync = ref.watch(salaryListProvider);
  return salariesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (list) {
      final Map<String, List<SalaryModel>> groups = {};
      for (final s in list) {
        groups.putIfAbsent(s.period, () => []).add(s);
      }

      final List<SalaryPeriodSummary> summaries = [];
      groups.forEach((period, items) {
        // Find oldest created date (first generated date)
        items.sort((a, b) {
          final dateCompare = a.createdDate.compareTo(b.createdDate);
          if (dateCompare != 0) return dateCompare;
          return a.createdTime.compareTo(b.createdTime);
        });
        final oldest = items.first;

        // Find latest updated date
        items.sort((a, b) {
          final dateCompare = b.lastUpdatedDate.compareTo(a.lastUpdatedDate);
          if (dateCompare != 0) return dateCompare;
          return b.lastUpdatedTime.compareTo(a.lastUpdatedTime);
        });
        final latest = items.first;

        final totalWorkers = items.length;
        final totalSalary = items.fold<double>(0.0, (sum, item) => sum + item.totalSalary);
        
        final paidItems = items.where((item) => item.paymentStatus == 'paid').toList();
        final pendingItems = items.where((item) => item.paymentStatus == 'pending').toList();

        final paidCount = paidItems.length;
        final pendingCount = pendingItems.length;
        final paidAmount = paidItems.fold<double>(0.0, (sum, item) => sum + item.totalSalary);
        final pendingAmount = pendingItems.fold<double>(0.0, (sum, item) => sum + item.totalSalary);

        summaries.add(SalaryPeriodSummary(
          period: period,
          generatedDate: oldest.createdDate,
          totalWorkers: totalWorkers,
          totalSalary: totalSalary,
          paidCount: paidCount,
          pendingCount: pendingCount,
          paidAmount: paidAmount,
          pendingAmount: pendingAmount,
          lastUpdated: '${latest.lastUpdatedDate} ${latest.lastUpdatedTime}',
        ));
      });

      // Sort periods by oldest generatedDate descending
      summaries.sort((a, b) => b.generatedDate.compareTo(a.generatedDate));
      return AsyncValue.data(summaries);
    },
  );
});
