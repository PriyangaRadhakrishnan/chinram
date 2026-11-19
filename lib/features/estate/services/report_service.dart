import '../models/estate_income_model.dart';
import '../models/salary_model.dart';
import '../models/weekly_expense_model.dart';
import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/tree_count_model.dart';
import '../models/tree_cutting_model.dart';
import '../models/worker_model.dart';
import '../repositories/estate_income_repository.dart';
import '../repositories/salary_repository.dart';
import '../repositories/weekly_expense_repository.dart';
import '../repositories/fertilizer_repository.dart';
import '../repositories/tree_count_repository.dart';
import '../repositories/tree_cutting_repository.dart';
import '../repositories/worker_repository.dart';
import '../models/manager_salary_model.dart';
import '../repositories/manager_salary_repository.dart';
import '../models/organic_fertilizer_model.dart';
import '../repositories/organic_fertilizer_repository.dart';

class ReportService {
  final EstateIncomeRepository incomeRepository;
  final SalaryRepository salaryRepository;
  final WeeklyExpenseRepository expenseRepository;
  final FertilizerRepository fertilizerRepository;
  final TreeCountRepository treeCountRepository;
  final TreeCuttingRepository treeCuttingRepository;
  final WorkerRepository workerRepository;
  final ManagerSalaryRepository managerSalaryRepository;
  final OrganicFertilizerRepository organicFertilizerRepository;

  const ReportService({
    required this.incomeRepository,
    required this.salaryRepository,
    required this.expenseRepository,
    required this.fertilizerRepository,
    required this.treeCountRepository,
    required this.treeCuttingRepository,
    required this.workerRepository,
    required this.managerSalaryRepository,
    required this.organicFertilizerRepository,
  });

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  DateTime _parseDateStr(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  // 1. Estate Income Report
  Future<List<EstateIncomeModel>> getIncomeReport(DateTime start, DateTime end) async {
    final list = await incomeRepository.getAll();
    return list.where((item) => _isWithinRange(item.date, start, end)).toList();
  }

  // 2. Salary Report
  Future<List<SalaryModel>> getSalaryReport(DateTime start, DateTime end) async {
    final list = await salaryRepository.getAll();
    return list.where((item) => _isWithinRange(_parseDateStr(item.startDate), start, end)).toList();
  }

  // Helper: Get worker profile name mapping
  Future<Map<String, WorkerModel>> getWorkerMap() async {
    final list = await workerRepository.getAll();
    final Map<String, WorkerModel> map = {};
    for (final w in list) {
      map[w.id] = w;
    }
    return map;
  }

  // 3. Other Expense Report
  Future<List<WeeklyExpenseModel>> getWeeklyExpenseReport(DateTime start, DateTime end) async {
    final list = await expenseRepository.getAll();
    return list.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
  }

  // 4. Fertilizer Purchase Report
  Future<List<FertilizerModel>> getFertilizerPurchaseReport(DateTime start, DateTime end) async {
    final list = await fertilizerRepository.getFertilizers();
    return list.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
  }

  // 5. Fertilizer Usage Report
  Future<List<FertilizerUsageModel>> getFertilizerUsageReport(DateTime start, DateTime end) async {
    final list = await fertilizerRepository.getUsages();
    return list.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
  }

  // Helper: get current stock levels mapping for fertilizer usage
  Future<Map<String, double>> getFertilizerStockMap() async {
    final txs = await fertilizerRepository.getTransactions();
    final Map<String, double> map = {};
    for (final tx in txs) {
      map[tx.fertilizerId] = (map[tx.fertilizerId] ?? 0.0) + tx.quantity;
    }
    return map;
  }

  // Helper: get fertilizer name mapping
  Future<Map<String, String>> getFertilizerNameMap() async {
    final list = await fertilizerRepository.getFertilizers();
    final Map<String, String> map = {};
    for (final f in list) {
      map[f.id] = f.name;
    }
    return map;
  }

  // 6. Tree Count Report
  Future<List<TreeCountModel>> getTreeCountReport(DateTime start, DateTime end) async {
    final list = await treeCountRepository.getTreeCounts();
    return list.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
  }

  // Helper: get current tree counts from ledger transactions
  Future<Map<String, int>> getTreeCountLedgerMap() async {
    final txs = await treeCountRepository.getLedgerTransactions();
    final Map<String, int> map = {};
    for (final tx in txs) {
      map[tx.treeCountId] = (map[tx.treeCountId] ?? 0) + tx.quantity;
    }
    return map;
  }

  // 7. Tree Cutting Report
  Future<List<TreeCuttingModel>> getTreeCuttingReport(DateTime start, DateTime end) async {
    final list = await treeCuttingRepository.getTreeCuttings();
    return list.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
  }

  // 8. Manager Told Salary Report
  Future<List<ManagerSalaryModel>> getManagerSalaryReport(DateTime start, DateTime end) async {
    final list = await managerSalaryRepository.getAll();
    return list.where((item) => _isWithinRange(_parseDateStr(item.fromDate), start, end)).toList();
  }

  // 9. Organic Fertilizer Report
  Future<List<OrganicFertilizerModel>> getOrganicFertilizerReport(DateTime start, DateTime end) async {
    final list = await organicFertilizerRepository.getAll();
    return list.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
  }

  // 10. Overall Estate Summary
  Future<Map<String, double>> getOverallEstateSummary(DateTime start, DateTime end) async {
    final incomes = await getIncomeReport(start, end);
    final salaries = await getSalaryReport(start, end);
    final managerSalaries = await getManagerSalaryReport(start, end);
    final expenses = await getWeeklyExpenseReport(start, end);
    final ferts = await getFertilizerPurchaseReport(start, end);
    final organicFerts = await getOrganicFertilizerReport(start, end);
    final cuttings = await getTreeCuttingReport(start, end);

    final totalIncome = incomes.fold<double>(0, (prev, element) => prev + element.totalAmount);
    final totalCuttings = cuttings.fold<double>(0, (prev, element) => prev + element.totalAmount);
    final totalSalary = salaries.fold<double>(0, (prev, element) => prev + element.totalSalary);
    final totalManagerSalary = managerSalaries.fold<double>(0, (prev, element) => prev + element.weeklySalary);
    final totalExpenses = expenses.fold<double>(0, (prev, element) => prev + element.amount);
    final totalFerts = ferts.fold<double>(0, (prev, element) => prev + element.totalPrice);
    final totalOrganicFerts = organicFerts.fold<double>(0, (prev, element) => prev + element.price);

    final aggregatedExpenses = totalSalary + totalManagerSalary + totalExpenses + totalFerts + totalOrganicFerts;
    final netProfit = (totalIncome + totalCuttings) - aggregatedExpenses;

    return {
      'totalIncome': totalIncome,
      'totalCuttings': totalCuttings,
      'totalSalary': totalSalary,
      'totalManagerSalary': totalManagerSalary,
      'totalExpenses': totalExpenses,
      'totalFerts': totalFerts,
      'totalOrganicFerts': totalOrganicFerts,
      'netProfit': netProfit,
    };
  }
}
