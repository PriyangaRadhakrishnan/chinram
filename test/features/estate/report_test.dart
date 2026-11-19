import 'package:flutter_test/flutter_test.dart';
import 'package:chinram_app/features/estate/models/estate_income_model.dart';
import 'package:chinram_app/features/estate/models/salary_model.dart';
import 'package:chinram_app/features/estate/models/weekly_expense_model.dart';
import 'package:chinram_app/features/estate/models/fertilizer_model.dart';
import 'package:chinram_app/features/estate/models/fertilizer_usage_model.dart';
import 'package:chinram_app/features/estate/models/fertilizer_transaction_model.dart';
import 'package:chinram_app/features/estate/models/tree_count_model.dart';
import 'package:chinram_app/features/estate/models/tree_count_ledger_model.dart';
import 'package:chinram_app/features/estate/models/tree_cutting_model.dart';
import 'package:chinram_app/features/estate/models/worker_model.dart';
import 'package:chinram_app/features/estate/models/salary_configuration_model.dart';
import 'package:chinram_app/features/estate/services/report_service.dart';
import 'package:chinram_app/features/estate/models/manager_salary_model.dart';
import 'package:chinram_app/features/estate/repositories/manager_salary_repository.dart';
import 'package:chinram_app/features/estate/repositories/estate_income_repository.dart';
import 'package:chinram_app/features/estate/repositories/salary_repository.dart';
import 'package:chinram_app/features/estate/repositories/weekly_expense_repository.dart';
import 'package:chinram_app/features/estate/repositories/fertilizer_repository.dart';
import 'package:chinram_app/features/estate/repositories/tree_count_repository.dart';
import 'package:chinram_app/features/estate/models/organic_fertilizer_model.dart';
import 'package:chinram_app/features/estate/repositories/organic_fertilizer_repository.dart';
import 'package:chinram_app/features/estate/repositories/tree_cutting_repository.dart';
import 'package:chinram_app/features/estate/repositories/worker_repository.dart';

// Mocks for repositories
class MockIncomeRepo implements EstateIncomeRepository {
  final List<EstateIncomeModel> list = [];
  @override
  Future<List<EstateIncomeModel>> getAll() async => list;
  @override
  Future<EstateIncomeModel?> getById(String id) async => null;
  @override
  Future<void> add(EstateIncomeModel income) async => list.add(income);
  @override
  Future<void> update(EstateIncomeModel income) async {}
  @override
  Future<void> delete(String id) async {}
}

class MockSalaryRepo implements SalaryRepository {
  final List<SalaryModel> list = [];
  @override
  Future<List<SalaryModel>> getAll() async => list;
  @override
  Future<SalaryModel?> getById(String id) async => null;
  @override
  Future<void> save(SalaryModel salary) async => list.add(salary);
  @override
  Future<void> delete(String id) async {}
  @override
  Future<SalaryConfigurationModel> getConfiguration() async => throw UnimplementedError();
  @override
  Future<void> saveConfiguration(SalaryConfigurationModel config) async {}
}

class MockExpenseRepo implements WeeklyExpenseRepository {
  final List<WeeklyExpenseModel> list = [];
  @override
  Future<List<WeeklyExpenseModel>> getAll() async => list;
  @override
  Future<WeeklyExpenseModel?> getById(String id) async => null;
  @override
  Future<void> save(WeeklyExpenseModel expense) async => list.add(expense);
  @override
  Future<void> delete(String id) async {}
}

class MockFertRepo implements FertilizerRepository {
  final List<FertilizerModel> list = [];
  @override
  Future<List<FertilizerModel>> getFertilizers() async => list;
  @override
  Future<FertilizerModel?> getFertilizerById(String id) async => null;
  @override
  Future<void> saveFertilizer(FertilizerModel f) async => list.add(f);
  @override
  Future<void> deleteFertilizer(String id) async {}
  @override
  Future<List<FertilizerUsageModel>> getUsages() async => [];
  @override
  Future<FertilizerUsageModel?> getUsageById(String id) async => null;
  @override
  Future<void> saveUsage(FertilizerUsageModel usage) async {}
  @override
  Future<void> deleteUsage(String id) async {}
  @override
  Future<List<FertilizerTransactionModel>> getTransactions() async => [];
  @override
  Future<void> saveTransaction(FertilizerTransactionModel tx) async {}
  @override
  Future<void> deleteTransactionsForReference(String referenceId) async {}
}

class MockTreeCountRepo implements TreeCountRepository {
  @override
  Future<List<TreeCountModel>> getTreeCounts() async => [];
  @override
  Future<TreeCountModel?> getTreeCountById(String id) async => null;
  @override
  Future<void> saveTreeCount(TreeCountModel r) async {}
  @override
  Future<void> deleteTreeCount(String id) async {}
  @override
  Future<List<TreeCountLedgerModel>> getLedgerTransactions() async => [];
  @override
  Future<void> saveLedgerTransaction(TreeCountLedgerModel tx) async {}
  @override
  Future<void> deleteLedgerTransactionsForReference(String refId) async {}
}

class MockTreeCuttingRepo implements TreeCuttingRepository {
  final List<TreeCuttingModel> list = [];
  @override
  Future<List<TreeCuttingModel>> getTreeCuttings() async => list;
  @override
  Future<TreeCuttingModel?> getTreeCuttingById(String id) async => null;
  @override
  Future<void> saveTreeCutting(TreeCuttingModel r) async => list.add(r);
  @override
  Future<void> deleteTreeCutting(String id) async {}
}

class MockWorkerRepo implements WorkerRepository {
  @override
  Future<List<WorkerModel>> getAll() async => [];
  @override
  Future<WorkerModel?> getById(String id) async => null;
  @override
  Future<void> add(WorkerModel worker) async {}
  @override
  Future<void> update(WorkerModel worker) async {}
  @override
  Future<void> delete(String id) async {}
}

class MockManagerSalaryRepo implements ManagerSalaryRepository {
  final List<ManagerSalaryModel> list = [];
  @override
  Future<List<ManagerSalaryModel>> getAll() async => list;
  @override
  Future<ManagerSalaryModel?> getById(String id) async => null;
  @override
  Future<void> save(ManagerSalaryModel record) async => list.add(record);
  @override
  Future<void> delete(String id) async {}
}

class MockOrganicFertRepo implements OrganicFertilizerRepository {
  final List<OrganicFertilizerModel> list = [];
  @override
  Future<List<OrganicFertilizerModel>> getAll() async => list;
  @override
  Future<OrganicFertilizerModel?> getById(String id) async => null;
  @override
  Future<void> save(OrganicFertilizerModel record) async => list.add(record);
  @override
  Future<void> delete(String id) async {}
}

void main() {
  group('ReportService Live Calculations Unit Tests', () {
    late ReportService service;
    late MockIncomeRepo incomeRepo;
    late MockSalaryRepo salaryRepo;
    late MockExpenseRepo expenseRepo;
    late MockFertRepo fertRepo;
    late MockOrganicFertRepo organicFertRepo;
    late MockTreeCuttingRepo cuttingRepo;
    late MockManagerSalaryRepo managerSalaryRepo;

    setUp(() {
      incomeRepo = MockIncomeRepo();
      salaryRepo = MockSalaryRepo();
      expenseRepo = MockExpenseRepo();
      fertRepo = MockFertRepo();
      organicFertRepo = MockOrganicFertRepo();
      cuttingRepo = MockTreeCuttingRepo();
      managerSalaryRepo = MockManagerSalaryRepo();

      service = ReportService(
        incomeRepository: incomeRepo,
        salaryRepository: salaryRepo,
        expenseRepository: expenseRepo,
        fertilizerRepository: fertRepo,
        treeCountRepository: MockTreeCountRepo(),
        treeCuttingRepository: cuttingRepo,
        workerRepository: MockWorkerRepo(),
        managerSalaryRepository: managerSalaryRepo,
        organicFertilizerRepository: organicFertRepo,
      );
    });

    test('calculates live net profit correctly', () async {
      final start = DateTime(2026, 7, 1);
      final end = DateTime(2026, 7, 31);

      // Income: ₹50,000
      await incomeRepo.add(EstateIncomeModel(
        id: 'inc-1',
        date: DateTime(2026, 7, 10),
        category: 'Coffee',
        productName: 'Coffee Beans',
        quantity: 500.0,
        unit: 'Kg',
        pricePerUnit: 100.0,
        totalAmount: 50000.0,
      ));

      // Tree cutting income: ₹15,000
      await cuttingRepo.saveTreeCutting(TreeCuttingModel(
        id: 'cut-1',
        date: '2026-07-15',
        treeName: 'Coffee',
        placeName: 'Plot A',
        numberOfTrees: 5,
        pricePerTree: 3000.0,
        totalAmount: 15000.0,
        createdDate: '2026-07-15',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-15',
        lastUpdatedTime: '12:00:00',
      ));

      // Salary expenses: ₹10,000
      await salaryRepo.save(SalaryModel(
        id: 'sal-1',
        workerId: 'w-1',
        period: 'July 2026',
        startDate: '2026-07-01',
        endDate: '2026-07-07',
        calculationMethod: 'attendance',
        durationUnit: 'days',
        durationValue: 5,
        presentDays: 5,
        dailyWage: 2000.0,
        totalSalary: 10000.0,
        paymentStatus: 'paid',
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      ));

      // Weekly expense: ₹3,000
      await expenseRepo.save(WeeklyExpenseModel(
        id: 'exp-1',
        date: '2026-07-12',
        category: 'Petrol',
        amount: 3000.0,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      ));

      // Fertilizer purchase: ₹7,000
      await fertRepo.saveFertilizer(FertilizerModel(
        id: 'fert-1',
        date: '2026-07-08',
        name: 'Urea',
        quantityPerBag: 50.0,
        unit: 'Kg',
        initialStock: 10,
        price: 7000.0,
        totalPrice: 7000.0,
        createdDate: '2026-07-03',
        createdTime: '12:00:00',
        lastUpdatedDate: '2026-07-03',
        lastUpdatedTime: '12:00:00',
      ));

      final summary = await service.getOverallEstateSummary(start, end);

      expect(summary['totalIncome'], 50000.0);
      expect(summary['totalCuttings'], 15000.0);
      expect(summary['totalSalary'], 10000.0);
      expect(summary['totalExpenses'], 3000.0);
      expect(summary['totalFerts'], 7000.0);
      expect(summary['netProfit'], 45000.0);
    });
  });
}
