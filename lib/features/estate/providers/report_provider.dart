import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';

// Import all repository providers
import 'estate_income_provider.dart';
import 'salary_provider.dart';
import 'weekly_expense_provider.dart';
import 'fertilizer_provider.dart';
import 'tree_count_provider.dart';
import 'tree_cutting_provider.dart';
import 'worker_provider.dart';
import 'manager_salary_provider.dart';
import 'organic_fertilizer_provider.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  final incomeRepo = ref.watch(estateIncomeRepositoryProvider);
  final salaryRepo = ref.watch(salaryRepositoryProvider);
  final expenseRepo = ref.watch(weeklyExpenseRepositoryProvider);
  final fertilizerRepo = ref.watch(fertilizerRepositoryProvider);
  final treeCountRepo = ref.watch(treeCountRepositoryProvider);
  final treeCuttingRepo = ref.watch(treeCuttingRepositoryProvider);
  final workerRepo = ref.watch(workerRepositoryProvider);
  final managerSalaryRepo = ref.watch(managerSalaryRepositoryProvider);
  final organicFertilizerRepo = ref.watch(organicFertilizerRepositoryProvider);

  return ReportService(
    incomeRepository: incomeRepo,
    salaryRepository: salaryRepo,
    expenseRepository: expenseRepo,
    fertilizerRepository: fertilizerRepo,
    treeCountRepository: treeCountRepo,
    treeCuttingRepository: treeCuttingRepo,
    workerRepository: workerRepo,
    managerSalaryRepository: managerSalaryRepo,
    organicFertilizerRepository: organicFertilizerRepo,
  );
});
