import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/bar_chart_widget.dart';
import '../models/estate_income_model.dart';
import '../models/salary_model.dart';
import '../models/manager_salary_model.dart';
import '../models/weekly_expense_model.dart';
import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/organic_fertilizer_model.dart';
import '../models/tree_count_model.dart';
import '../models/tree_cutting_model.dart';
import '../models/attendance_model.dart';
import '../providers/estate_income_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/manager_salary_provider.dart';
import '../providers/weekly_expense_provider.dart';
import '../providers/fertilizer_provider.dart';
import '../providers/organic_fertilizer_provider.dart';
import '../providers/tree_count_provider.dart';
import '../providers/tree_cutting_provider.dart';
import '../providers/worker_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/estate_provider.dart';
import '../utils/report_export_helper.dart';

class RecentActivityItem {
  final IconData icon;
  final String module;
  final String description;
  final String date;
  final String time;
  final VoidCallback onTap;
  final DateTime dateTime;

  const RecentActivityItem({
    required this.icon,
    required this.module,
    required this.description,
    required this.date,
    required this.time,
    required this.onTap,
    required this.dateTime,
  });
}

class ReportDashboardScreen extends ConsumerStatefulWidget {
  const ReportDashboardScreen({super.key});

  @override
  ConsumerState<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends ConsumerState<ReportDashboardScreen> {
  String _selectedDateRangeType = 'This Month'; // default
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEndDate = DateTime.now();

  // Local search queries per section
  String _incomeSearch = '';
  String _salarySearch = '';
  String _managerSalarySearch = '';
  String _expenseSearch = '';
  String _purchaseSearch = '';
  String _organicFertilizerSearch = '';
  String _usageSearch = '';
  String _treeCountSearch = '';
  String _treeCuttingSearch = '';
  String _attendanceSearch = '';

  final List<String> _dateRangeTypes = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'Custom Date Range',
  ];

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    DateTime start = now;
    DateTime end = now;

    switch (_selectedDateRangeType) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Custom Date Range':
        start = _customStartDate;
        end = _customEndDate;
        break;
    }
    return DateTimeRange(start: start, end: end);
  }

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

  String _formatPrettyDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = parts[2].padLeft(2, '0');
        final monthIdx = int.tryParse(parts[1]);
        final year = parts[0];
        if (monthIdx != null && monthIdx >= 1 && monthIdx <= 12) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '$day ${months[monthIdx - 1]} $year';
        }
      }
      return dateStr;
    }
  }

  String _formatPrettyTime(String timeStr) {
    final ms = int.tryParse(timeStr);
    if (ms != null && ms > 1000000000000) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  DateTime _getDateTime(String createdDate, String createdTime) {
    try {
      return DateTime.parse('${createdDate}T$createdTime');
    } catch (_) {
      try {
        return DateTime.parse(createdDate);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  DateTime _resolveDateTime(String id, DateTime baseDate) {
    final ms = int.tryParse(id);
    if (ms != null && ms > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return baseDate;
  }

  String _formatBags(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  String _formatLoads(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  Future<void> _selectCustomDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _customStartDate : _customEndDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
          if (_customStartDate.isAfter(_customEndDate)) {
            _customEndDate = _customStartDate;
          }
        } else {
          _customEndDate = picked;
          if (_customEndDate.isBefore(_customStartDate)) {
            _customStartDate = _customEndDate;
          }
        }
      });
    }
  }

  // Export handlers
  void _exportReport(bool isPdf, {
    required String periodText,
    required Map<String, String> summaryMap,
    required List<EstateIncomeModel> filteredIncomes,
    required List<SalaryModel> filteredSalaries,
    required List<ManagerSalaryModel> filteredManagerSalaries,
    required List<WeeklyExpenseModel> filteredExpenses,
    required List<FertilizerModel> filteredPurchases,
    required List<OrganicFertilizerModel> filteredOrganicPurchases,
    required List<FertilizerUsageModel> filteredUsages,
    required List<TreeCountModel> filteredTreeCounts,
    required List<TreeCuttingModel> filteredTreeCuttings,
    required Map<String, String> workerMap,
    required Map<String, String> fertMap,
    required Map<String, int> treeLedgerMap,
    required Map<String, double> fertStockMap,
  }) async {
    // Construct rows for PDF/Excel exports
    final incomeRows = filteredIncomes.map((item) {
      final isCardamom = item.category.toLowerCase() == 'cardamom';
      return [
        _formatPrettyDate(item.date.toString().split(' ')[0]),
        item.category,
        item.productName,
        '${item.quantity} ${item.unit}',
        isCardamom ? '${item.greenQuantity ?? 0.0} ${item.unit}' : '-',
        isCardamom ? '${item.dryQuantity ?? 0.0} ${item.unit}' : '-',
        isCardamom ? '${item.percent?.toStringAsFixed(2) ?? "0.00"}%' : '-',
        '₹${item.pricePerUnit.toStringAsFixed(2)}',
        '₹${item.totalAmount.toStringAsFixed(2)}',
      ];
    }).toList();

    final salaryRows = filteredSalaries.map((item) => [
      workerMap[item.workerId] ?? 'Unknown',
      item.period,
      '₹${item.totalSalary.toStringAsFixed(2)}',
      item.paymentStatus.toUpperCase(),
      item.paymentDate != null ? _formatPrettyDate(item.paymentDate!) : '-',
    ]).toList();

    final managerSalaryRows = filteredManagerSalaries.map((item) => [
      _formatPrettyDate(item.fromDate),
      _formatPrettyDate(item.toDate),
      '₹${item.weeklySalary.toStringAsFixed(2)}',
      _formatPrettyDate(item.createdDate),
    ]).toList();

    final expenseRows = filteredExpenses.map((item) => [
      _formatPrettyDate(item.date),
      item.category,
      item.notes ?? '-',
      '₹${item.amount.toStringAsFixed(2)}',
    ]).toList();

    final purchaseRows = filteredPurchases.map((item) => [
      _formatPrettyDate(item.date),
      item.name,
      '${item.initialStock} Bags',
      '₹${item.price.toStringAsFixed(2)}',
      '₹${item.totalPrice.toStringAsFixed(2)}',
    ]).toList();

    final organicFertilizerRows = filteredOrganicPurchases.map((item) => [
      _formatPrettyDate(item.date),
      item.name,
      _formatLoads(item.loads),
      item.unit,
      '₹${item.price.toStringAsFixed(2)}',
    ]).toList();

    final usageRows = filteredUsages.map((item) => [
      _formatPrettyDate(item.date),
      fertMap[item.fertilizerId] ?? 'Unknown',
      '${_formatBags(item.bagsUsed)} Bags',
    ]).toList();

    final treeCountRows = filteredTreeCounts.map((item) => [
      _formatPrettyDate(item.date),
      item.treeName,
      item.plotName,
      '${treeLedgerMap[item.id] ?? item.initialCount} Trees',
    ]).toList();

    final treeCuttingRows = filteredTreeCuttings.map((item) => [
      _formatPrettyDate(item.date),
      item.treeName ?? '-',
      item.placeName ?? '-',
      item.numberOfTrees != null ? '${item.numberOfTrees} Trees' : '-',
      item.pricePerTree != null ? '₹${item.pricePerTree!.toStringAsFixed(2)}' : '-',
      '₹${item.totalAmount.toStringAsFixed(2)}',
    ]).toList();

    if (isPdf) {
      await ReportExportHelper.sharePdf(
        dateRange: periodText,
        summary: summaryMap,
        incomeRows: incomeRows,
        salaryRows: salaryRows,
        managerSalaryRows: managerSalaryRows,
        expenseRows: expenseRows,
        purchaseRows: purchaseRows,
        organicFertilizerRows: organicFertilizerRows,
        usageRows: usageRows,
        treeCountRows: treeCountRows,
        treeCuttingRows: treeCuttingRows,
      );
    } else {
      await ReportExportHelper.shareExcel(
        dateRange: periodText,
        summary: summaryMap,
        incomeRows: incomeRows,
        salaryRows: salaryRows,
        managerSalaryRows: managerSalaryRows,
        expenseRows: expenseRows,
        purchaseRows: purchaseRows,
        organicFertilizerRows: organicFertilizerRows,
        usageRows: usageRows,
        treeCountRows: treeCountRows,
        treeCuttingRows: treeCuttingRows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Watch raw lists from Riverpod (reactive update)
    final incomesAsync = ref.watch(estateIncomeListProvider);
    final salariesAsync = ref.watch(salaryListProvider);
    final managerSalariesAsync = ref.watch(managerSalaryListProvider);
    final expensesAsync = ref.watch(weeklyExpenseListProvider);
    final purchasesAsync = ref.watch(fertilizerInventoryProvider);
    final organicPurchasesAsync = ref.watch(organicFertilizerListProvider);
    final usagesAsync = ref.watch(fertilizerUsagesProvider);
    final treeCountsAsync = ref.watch(treeCountListProvider);
    final treeCuttingsAsync = ref.watch(treeCuttingListProvider);
    final workersAsync = ref.watch(workerListProvider);
    final fertTxsAsync = ref.watch(fertilizerTransactionsProvider);
    final treeTxsAsync = ref.watch(treeCountTransactionsProvider);
    final attendancesAsync = ref.watch(attendanceHistoryProvider);
    final dashboardDataAsync = ref.watch(estateDashboardDataProvider);

    final isLoading = incomesAsync.isLoading ||
        salariesAsync.isLoading ||
        managerSalariesAsync.isLoading ||
        expensesAsync.isLoading ||
        purchasesAsync.isLoading ||
        organicPurchasesAsync.isLoading ||
        usagesAsync.isLoading ||
        treeCountsAsync.isLoading ||
        treeCuttingsAsync.isLoading ||
        workersAsync.isLoading ||
        attendancesAsync.isLoading;

    if (isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Updating live records...'),
      );
    }

    // 2. Fetch maps for names & stocks
    final workers = workersAsync.value ?? [];
    final workerMap = {for (var w in workers) w.id: w.name ?? 'Unknown'};

    final purchases = purchasesAsync.value ?? [];
    final fertMap = {for (var f in purchases) f.id: f.name};

    // Calculate fertilizer stocks
    final fertTxs = fertTxsAsync.value ?? [];
    final Map<String, double> fertStockMap = {};
    for (final tx in fertTxs) {
      fertStockMap[tx.fertilizerId] = (fertStockMap[tx.fertilizerId] ?? 0.0) + tx.quantity;
    }

    // Calculate tree count ledger
    final treeTxs = treeTxsAsync.value ?? [];
    final Map<String, int> treeLedgerMap = {};
    for (final tx in treeTxs) {
      treeLedgerMap[tx.treeCountId] = (treeLedgerMap[tx.treeCountId] ?? 0) + tx.quantity;
    }

    // 3. Apply Date Filtering locally
    final range = _getDateRange();
    final start = range.start;
    final end = range.end;

    final filteredIncomes = (incomesAsync.value ?? []).where((item) => _isWithinRange(item.date, start, end)).toList();
    final filteredSalaries = (salariesAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.startDate), start, end)).toList();
    final filteredManagerSalaries = (managerSalariesAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.fromDate), start, end)).toList();
    final filteredExpenses = (expensesAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
    final filteredPurchases = purchases.where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
    final filteredOrganicPurchases = (organicPurchasesAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
    final filteredUsages = (usagesAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
    final filteredTreeCounts = (treeCountsAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
    final filteredTreeCuttings = (treeCuttingsAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();
    final filteredAttendances = (attendancesAsync.value ?? []).where((item) => _isWithinRange(_parseDateStr(item.date), start, end)).toList();

    // 4. Calculate Financial KPIs
    final totalIncome = filteredIncomes.fold<double>(0, (p, e) => p + e.totalAmount);
    final totalTreeCuttingIncome = filteredTreeCuttings.fold<double>(0, (p, e) => p + e.totalAmount);
    final totalSalary = filteredSalaries.fold<double>(0, (p, e) => p + e.totalSalary);
    final totalManagerSalary = filteredManagerSalaries.fold<double>(0, (p, e) => p + e.weeklySalary);
    final totalWeeklyExpenses = filteredExpenses.fold<double>(0, (p, e) => p + e.amount);
    final totalFertilizerPurchases = filteredPurchases.fold<double>(0, (p, e) => p + e.totalPrice);
    final totalOrganicFertilizerPurchases = filteredOrganicPurchases.fold<double>(0, (p, e) => p + e.price);

    final totalExpenses = totalSalary + totalManagerSalary + totalWeeklyExpenses + totalFertilizerPurchases + totalOrganicFertilizerPurchases;
    final netProfit = (totalIncome + totalTreeCuttingIncome) - totalExpenses;

    final periodText = '$_selectedDateRangeType (${start.toString().split(' ')[0]} - ${end.toString().split(' ')[0]})';
    final summaryMap = {
      'Total Income': '₹${totalIncome.toStringAsFixed(2)}',
      'Tree Cutting Income': '₹${totalTreeCuttingIncome.toStringAsFixed(2)}',
      'Worker Salary': '₹${totalSalary.toStringAsFixed(2)}',
      'Manager Told Salary': '₹${totalManagerSalary.toStringAsFixed(2)}',
      'Other Expenses': '₹${totalWeeklyExpenses.toStringAsFixed(2)}',
      'Fertilizer Purchases': '₹${totalFertilizerPurchases.toStringAsFixed(2)}',
      'Organic Fertilizer Purchases': '₹${totalOrganicFertilizerPurchases.toStringAsFixed(2)}',
      'Total Expenses': '₹${totalExpenses.toStringAsFixed(2)}',
      'Net Profit': '₹${netProfit.toStringAsFixed(2)}',
    };

    // Calculate total records to check for empty states
    final totalRecordsCount = filteredIncomes.length +
        filteredSalaries.length +
        filteredManagerSalaries.length +
        filteredExpenses.length +
        filteredPurchases.length +
        filteredOrganicPurchases.length +
        filteredUsages.length +
        filteredTreeCounts.length +
        filteredTreeCuttings.length +
        filteredAttendances.length;

    // Grid column count parameters based on responsive sizing
    final kpiCrossAxisCount = context.isDesktop
        ? 4
        : (context.isTablet ? 3 : 2);

    // Build Recent Activities Timeline List
    final List<RecentActivityItem> activities = [];

    if (incomesAsync.hasValue) {
      for (final item in incomesAsync.value!) {
        activities.add(RecentActivityItem(
          icon: Icons.attach_money,
          module: '💰 Income Added',
          description: 'Added ₹${item.totalAmount.toStringAsFixed(0)} income for ${item.productName}',
          date: _formatPrettyDate(item.date.toString().split(' ')[0]),
          time: _formatPrettyTime(item.id),
          dateTime: _resolveDateTime(item.id, item.date),
          onTap: () {},
        ));
      }
    }
    if (salariesAsync.hasValue) {
      for (final item in salariesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.payments,
          module: '💵 Salary Generated',
          description: 'Generated ${item.period} salary',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (managerSalariesAsync.hasValue) {
      for (final item in managerSalariesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.payments,
          module: '💵 Manager Told Salary Added',
          description: 'Added Manager Told Salary ₹${item.weeklySalary.toStringAsFixed(0)}',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (expensesAsync.hasValue) {
      for (final item in expensesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.money_off,
          module: '📝 Expense Added',
          description: 'Added ${item.category} expense ₹${item.amount.toStringAsFixed(0)}',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (purchasesAsync.hasValue) {
      for (final item in purchasesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.warehouse,
          module: '🌱 Fertilizer Purchased',
          description: 'Added ${item.initialStock} bags of ${item.name}',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (usagesAsync.hasValue && purchasesAsync.hasValue) {
      for (final item in usagesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        final fert = purchasesAsync.value!.where((f) => f.id == item.fertilizerId).firstOrNull;
        activities.add(RecentActivityItem(
          icon: Icons.remove_shopping_cart,
          module: '🌱 Fertilizer Stock Usage Logged',
          description: 'Used ${item.bagsUsed} bags of ${fert?.name ?? "fertilizer"}',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (organicPurchasesAsync.hasValue) {
      for (final item in organicPurchasesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.grass,
          module: '🌿 Organic Fertilizer Used',
          description: 'Manured ${item.loads} ${item.unit.toLowerCase()} loads of ${item.name}',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (treeCountsAsync.hasValue) {
      for (final item in treeCountsAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.nature,
          module: '🌳 Tree Count Updated',
          description: 'Updated ${item.treeName} tree count',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (treeCuttingsAsync.hasValue) {
      for (final item in treeCuttingsAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.nature_people,
          module: '🪓 Mara Vettu Added',
          description: 'Recorded cutting of ${item.numberOfTrees ?? 0} ${item.treeName ?? "trees"} trees',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }
    if (attendancesAsync.hasValue) {
      for (final item in attendancesAsync.value!) {
        final dt = _getDateTime(item.createdDate, item.createdTime);
        activities.add(RecentActivityItem(
          icon: Icons.how_to_reg,
          module: '📅 Attendance Saved',
          description: 'Attendance saved for ${_formatPrettyDate(item.date)}',
          date: _formatPrettyDate(item.createdDate),
          time: _formatPrettyTime(item.createdTime),
          dateTime: dt,
          onTap: () {},
        ));
      }
    }

    // Sort recent activities by time descending
    activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final timelineActivities = activities.take(5).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          toolbarHeight: 80.0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Live Estate Reports',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Real-time financial and operational analytics',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export Combined PDF',
              onPressed: () => _exportReport(
                true,
                periodText: periodText,
                summaryMap: summaryMap,
                filteredIncomes: filteredIncomes,
                filteredSalaries: filteredSalaries,
                filteredManagerSalaries: filteredManagerSalaries,
                filteredExpenses: filteredExpenses,
                filteredPurchases: filteredPurchases,
                filteredOrganicPurchases: filteredOrganicPurchases,
                filteredUsages: filteredUsages,
                filteredTreeCounts: filteredTreeCounts,
                filteredTreeCuttings: filteredTreeCuttings,
                workerMap: workerMap,
                fertMap: fertMap,
                treeLedgerMap: treeLedgerMap,
                fertStockMap: fertStockMap,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.table_view),
              tooltip: 'Export Combined Excel',
              onPressed: () => _exportReport(
                false,
                periodText: periodText,
                summaryMap: summaryMap,
                filteredIncomes: filteredIncomes,
                filteredSalaries: filteredSalaries,
                filteredManagerSalaries: filteredManagerSalaries,
                filteredExpenses: filteredExpenses,
                filteredPurchases: filteredPurchases,
                filteredOrganicPurchases: filteredOrganicPurchases,
                filteredUsages: filteredUsages,
                filteredTreeCounts: filteredTreeCounts,
                filteredTreeCuttings: filteredTreeCuttings,
                workerMap: workerMap,
                fertMap: fertMap,
                treeLedgerMap: treeLedgerMap,
                fertStockMap: fertStockMap,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Report',
              onPressed: () => _exportReport(
                true,
                periodText: periodText,
                summaryMap: summaryMap,
                filteredIncomes: filteredIncomes,
                filteredSalaries: filteredSalaries,
                filteredManagerSalaries: filteredManagerSalaries,
                filteredExpenses: filteredExpenses,
                filteredPurchases: filteredPurchases,
                filteredOrganicPurchases: filteredOrganicPurchases,
                filteredUsages: filteredUsages,
                filteredTreeCounts: filteredTreeCounts,
                filteredTreeCuttings: filteredTreeCuttings,
                workerMap: workerMap,
                fertMap: fertMap,
                treeLedgerMap: treeLedgerMap,
                fertStockMap: fertStockMap,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Date Range Filter Panel
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                elevation: 1.5,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Select Live Filter Period',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Reset Filter'),
                                onPressed: () {
                                  setState(() {
                                    _selectedDateRangeType = 'This Month';
                                    _incomeSearch = '';
                                    _salarySearch = '';
                                    _managerSalarySearch = '';
                                    _expenseSearch = '';
                                    _purchaseSearch = '';
                                    _organicFertilizerSearch = '';
                                    _usageSearch = '';
                                    _treeCountSearch = '';
                                    _treeCuttingSearch = '';
                                    _attendanceSearch = '';
                                  });
                                  ref.invalidate(estateDashboardDataProvider);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Refresh Reports',
                                onPressed: () {
                                  ref.invalidate(estateDashboardDataProvider);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedDateRangeType,
                              decoration: InputDecoration(
                                labelText: 'Time Period',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _dateRangeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedDateRangeType = val ?? 'This Month';
                                });
                              },
                            ),
                          ),
                          if (_selectedDateRangeType == 'Custom Date Range') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectCustomDate(context, true),
                                      icon: const Icon(Icons.calendar_today, size: 14),
                                      label: Text(start.toString().split(' ')[0]),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('to', style: TextStyle(color: AppColors.textSecondary)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectCustomDate(context, false),
                                      icon: const Icon(Icons.calendar_today, size: 14),
                                      label: Text(end.toString().split(' ')[0]),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (totalRecordsCount == 0) ...[
                // Premium Empty State Illustration Layout
                Card(
                  elevation: 1.5,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.bar_chart_outlined,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Estate Report Data',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start adding estate records to generate reports.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // KPI Cards Grid (Responsive Layout)
                GridView.count(
                  crossAxisCount: kpiCrossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _buildKpiCard(
                      context,
                      title: 'Total Income',
                      value: '₹${(totalIncome + totalTreeCuttingIncome).toStringAsFixed(0)}',
                      icon: Icons.arrow_upward,
                      color: const Color(0xFF2E7D32), // Green
                      trend: '▲ Updated Today',
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Total Expenses',
                      value: '₹${totalExpenses.toStringAsFixed(0)}',
                      icon: Icons.arrow_downward,
                      color: const Color(0xFFD32F2F), // Red
                      trend: '▼ Based on Period',
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Net Profit',
                      value: '₹${netProfit.toStringAsFixed(0)}',
                      icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: netProfit >= 0 ? const Color(0xFF1976D2) : const Color(0xFFD32F2F), // Blue if positive, Red if negative
                      trend: netProfit >= 0 ? '▲ Updated Today' : '▼ Updated Today',
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Total Salary',
                      value: '₹${(totalSalary + totalManagerSalary).toStringAsFixed(0)}',
                      icon: Icons.badge,
                      color: const Color(0xFF795548), // Brown
                      trend: '▲ Based on Period',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Financial Insights Segment
                Card(
                  margin: const EdgeInsets.only(bottom: 28),
                  elevation: 1.5,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Income vs Expenses Ratio
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Income vs Expenses Ratio',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(totalIncome + totalTreeCuttingIncome) > 0 ? ((totalExpenses / (totalIncome + totalTreeCuttingIncome)) * 100).toStringAsFixed(0) : 0}% Expenses',
                              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFD32F2F)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (totalIncome + totalTreeCuttingIncome) > 0
                                ? (totalExpenses / (totalIncome + totalTreeCuttingIncome)).clamp(0.0, 1.0)
                                : 0.0,
                            backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            color: const Color(0xFFD32F2F),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Expense & Salary Distribution Layout
                        context.isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildExpenseDistribution(context, totalExpenses, totalSalary + totalManagerSalary, totalFertilizerPurchases + totalOrganicFertilizerPurchases, totalWeeklyExpenses)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildSalaryDistribution(context, totalSalary + totalManagerSalary, totalSalary, totalManagerSalary)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildExpenseDistribution(context, totalExpenses, totalSalary + totalManagerSalary, totalFertilizerPurchases + totalOrganicFertilizerPurchases, totalWeeklyExpenses),
                                  const SizedBox(height: 24),
                                  _buildSalaryDistribution(context, totalSalary + totalManagerSalary, totalSalary, totalManagerSalary),
                                ],
                              ),
                        const SizedBox(height: 24),

                        // Monthly Net Profit Trend Chart
                        if (dashboardDataAsync.hasValue)
                          BarChartWidget(
                            title: 'Estate Financial Overview (Net Profit)',
                            dataPoints: dashboardDataAsync.value!.chartData.map((dp) {
                              return BarChartDataPoint(label: dp.label, value: dp.value);
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Detailed Category Sub-reports',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Section 1: Estate Income
                _buildCategorySection(
                  context: context,
                  title: 'Estate Income',
                  subtitle: 'Total Collected: ₹${(totalIncome + totalTreeCuttingIncome).toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                  searchHint: 'Search product or category...',
                  searchVal: _incomeSearch,
                  onSearchChanged: (val) => setState(() => _incomeSearch = val),
                  recordsCount: filteredIncomes.length,
                  child: _buildIncomeList(filteredIncomes, context.isDesktop || context.isTablet),
                ),

                // Section 2: Worker Salaries
                _buildCategorySection(
                  context: context,
                  title: 'Worker Salary',
                  subtitle: 'Total Wages: ₹${totalSalary.toStringAsFixed(2)}',
                  icon: Icons.badge_outlined,
                  searchHint: 'Search worker or period...',
                  searchVal: _salarySearch,
                  onSearchChanged: (val) => setState(() => _salarySearch = val),
                  recordsCount: filteredSalaries.length,
                  child: _buildSalaryList(filteredSalaries, workerMap, context.isDesktop || context.isTablet),
                ),

                // Section 2.5: Manager Told Salaries
                _buildCategorySection(
                  context: context,
                  title: 'Manager Told Salary',
                  subtitle: 'Total Wages: ₹${totalManagerSalary.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                  searchHint: 'Search period dates (yyyy-MM-dd)...',
                  searchVal: _managerSalarySearch,
                  onSearchChanged: (val) => setState(() => _managerSalarySearch = val),
                  recordsCount: filteredManagerSalaries.length,
                  child: _buildManagerSalaryList(filteredManagerSalaries, context.isDesktop || context.isTablet),
                ),

                // Section 3: Other Expenses
                _buildCategorySection(
                  context: context,
                  title: 'Other Expenses',
                  subtitle: 'Total Spent: ₹${totalWeeklyExpenses.toStringAsFixed(2)}',
                  icon: Icons.shopping_bag_outlined,
                  searchHint: 'Search category or notes...',
                  searchVal: _expenseSearch,
                  onSearchChanged: (val) => setState(() => _expenseSearch = val),
                  recordsCount: filteredExpenses.length,
                  child: _buildExpenseList(filteredExpenses, context.isDesktop || context.isTablet),
                ),

                // Section 4: Fertilizer Purchases
                _buildCategorySection(
                  context: context,
                  title: 'Fertilizer',
                  subtitle: 'Total Purchases: ₹${totalFertilizerPurchases.toStringAsFixed(2)}',
                  icon: Icons.science_outlined,
                  searchHint: 'Search fertilizer...',
                  searchVal: _purchaseSearch,
                  onSearchChanged: (val) => setState(() => _purchaseSearch = val),
                  recordsCount: filteredPurchases.length,
                  child: _buildPurchaseList(filteredPurchases, context.isDesktop || context.isTablet),
                ),

                // Section 4.5: Organic Fertilizer Purchases
                _buildCategorySection(
                  context: context,
                  title: 'Organic Fertilizer',
                  subtitle: 'Total Spent: ₹${totalOrganicFertilizerPurchases.toStringAsFixed(2)}',
                  icon: Icons.grass_outlined,
                  searchHint: 'Search organic name...',
                  searchVal: _organicFertilizerSearch,
                  onSearchChanged: (val) => setState(() => _organicFertilizerSearch = val),
                  recordsCount: filteredOrganicPurchases.length,
                  child: _buildOrganicFertilizerList(filteredOrganicPurchases, context.isDesktop || context.isTablet),
                ),

                // Section 5: Fertilizer Usages
                _buildCategorySection(
                  context: context,
                  title: 'Fertilizer Usages',
                  subtitle: 'Total Bags Used: ${_formatBags(filteredUsages.fold<double>(0.0, (p, e) => p + e.bagsUsed))} Bags',
                  icon: Icons.science,
                  searchHint: 'Search usage...',
                  searchVal: _usageSearch,
                  onSearchChanged: (val) => setState(() => _usageSearch = val),
                  recordsCount: filteredUsages.length,
                  child: _buildUsageList(filteredUsages, fertMap, fertStockMap, context.isDesktop || context.isTablet),
                ),

                // Section 6: Tree Counts
                _buildCategorySection(
                  context: context,
                  title: 'Tree Count',
                  subtitle: 'Forest Population: ${filteredTreeCounts.fold<int>(0, (p, e) => p + (treeLedgerMap[e.id] ?? e.initialCount))} Trees',
                  icon: Icons.nature_outlined,
                  searchHint: 'Search plot or tree...',
                  searchVal: _treeCountSearch,
                  onSearchChanged: (val) => setState(() => _treeCountSearch = val),
                  recordsCount: filteredTreeCounts.length,
                  child: _buildTreeCountList(filteredTreeCounts, treeLedgerMap, context.isDesktop || context.isTablet),
                ),

                // Section 7: Tree Cuttings
                _buildCategorySection(
                  context: context,
                  title: 'Mara Vettu',
                  subtitle: 'Cutting Revenue: ₹${totalTreeCuttingIncome.toStringAsFixed(2)}',
                  icon: Icons.nature_people_outlined,
                  searchHint: 'Search cut logs...',
                  searchVal: _treeCuttingSearch,
                  onSearchChanged: (val) => setState(() => _treeCuttingSearch = val),
                  recordsCount: filteredTreeCuttings.length,
                  child: _buildTreeCuttingList(filteredTreeCuttings, context.isDesktop || context.isTablet),
                ),

                // Section 8: Attendance Logs
                _buildCategorySection(
                  context: context,
                  title: 'Attendance',
                  subtitle: 'Attendance Saved: ${filteredAttendances.length} Days',
                  icon: Icons.how_to_reg_outlined,
                  searchHint: 'Search date (yyyy-MM-dd)...',
                  searchVal: _attendanceSearch,
                  onSearchChanged: (val) => setState(() => _attendanceSearch = val),
                  recordsCount: filteredAttendances.length,
                  child: _buildAttendanceList(filteredAttendances, context.isDesktop || context.isTablet),
                ),
                const SizedBox(height: 28),

                // Recent Report Activity Timeline Section
                Card(
                  margin: const EdgeInsets.only(bottom: 28),
                  elevation: 1.5,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Report Activity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActivityTimeline(timelineActivities, context),
                      ],
                    ),
                  ),
                ),

                // Dedicated Export & Share Panel
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 1.5,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Export & Share',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        context.isDesktop
                            ? Row(
                                children: [
                                  Expanded(child: _buildExportButton(context, 'Export PDF', Icons.picture_as_pdf, const Color(0xFFD32F2F), () => _exportReport(true, periodText: periodText, summaryMap: summaryMap, filteredIncomes: filteredIncomes, filteredSalaries: filteredSalaries, filteredManagerSalaries: filteredManagerSalaries, filteredExpenses: filteredExpenses, filteredPurchases: filteredPurchases, filteredOrganicPurchases: filteredOrganicPurchases, filteredUsages: filteredUsages, filteredTreeCounts: filteredTreeCounts, filteredTreeCuttings: filteredTreeCuttings, workerMap: workerMap, fertMap: fertMap, treeLedgerMap: treeLedgerMap, fertStockMap: fertStockMap))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildExportButton(context, 'Export Excel', Icons.table_view, const Color(0xFF2E7D32), () => _exportReport(false, periodText: periodText, summaryMap: summaryMap, filteredIncomes: filteredIncomes, filteredSalaries: filteredSalaries, filteredManagerSalaries: filteredManagerSalaries, filteredExpenses: filteredExpenses, filteredPurchases: filteredPurchases, filteredOrganicPurchases: filteredOrganicPurchases, filteredUsages: filteredUsages, filteredTreeCounts: filteredTreeCounts, filteredTreeCuttings: filteredTreeCuttings, workerMap: workerMap, fertMap: fertMap, treeLedgerMap: treeLedgerMap, fertStockMap: fertStockMap))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildExportButton(context, 'Share Report', Icons.share_outlined, theme.colorScheme.primary, () => _exportReport(true, periodText: periodText, summaryMap: summaryMap, filteredIncomes: filteredIncomes, filteredSalaries: filteredSalaries, filteredManagerSalaries: filteredManagerSalaries, filteredExpenses: filteredExpenses, filteredPurchases: filteredPurchases, filteredOrganicPurchases: filteredOrganicPurchases, filteredUsages: filteredUsages, filteredTreeCounts: filteredTreeCounts, filteredTreeCuttings: filteredTreeCuttings, workerMap: workerMap, fertMap: fertMap, treeLedgerMap: treeLedgerMap, fertStockMap: fertStockMap))),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildExportButton(context, 'Export PDF', Icons.picture_as_pdf, const Color(0xFFD32F2F), () => _exportReport(true, periodText: periodText, summaryMap: summaryMap, filteredIncomes: filteredIncomes, filteredSalaries: filteredSalaries, filteredManagerSalaries: filteredManagerSalaries, filteredExpenses: filteredExpenses, filteredPurchases: filteredPurchases, filteredOrganicPurchases: filteredOrganicPurchases, filteredUsages: filteredUsages, filteredTreeCounts: filteredTreeCounts, filteredTreeCuttings: filteredTreeCuttings, workerMap: workerMap, fertMap: fertMap, treeLedgerMap: treeLedgerMap, fertStockMap: fertStockMap)),
                                  const SizedBox(height: 12),
                                  _buildExportButton(context, 'Export Excel', Icons.table_view, const Color(0xFF2E7D32), () => _exportReport(false, periodText: periodText, summaryMap: summaryMap, filteredIncomes: filteredIncomes, filteredSalaries: filteredSalaries, filteredManagerSalaries: filteredManagerSalaries, filteredExpenses: filteredExpenses, filteredPurchases: filteredPurchases, filteredOrganicPurchases: filteredOrganicPurchases, filteredUsages: filteredUsages, filteredTreeCounts: filteredTreeCounts, filteredTreeCuttings: filteredTreeCuttings, workerMap: workerMap, fertMap: fertMap, treeLedgerMap: treeLedgerMap, fertStockMap: fertStockMap)),
                                  const SizedBox(height: 12),
                                  _buildExportButton(context, 'Share Report', Icons.share_outlined, theme.colorScheme.primary, () => _exportReport(true, periodText: periodText, summaryMap: summaryMap, filteredIncomes: filteredIncomes, filteredSalaries: filteredSalaries, filteredManagerSalaries: filteredManagerSalaries, filteredExpenses: filteredExpenses, filteredPurchases: filteredPurchases, filteredOrganicPurchases: filteredOrganicPurchases, filteredUsages: filteredUsages, filteredTreeCounts: filteredTreeCounts, filteredTreeCuttings: filteredTreeCuttings, workerMap: workerMap, fertMap: fertMap, treeLedgerMap: treeLedgerMap, fertStockMap: fertStockMap)),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseDistribution(
    BuildContext context,
    double totalExpenses,
    double salaries,
    double fertilizers,
    double otherExpenses,
  ) {
    final theme = Theme.of(context);
    final denom = totalExpenses > 0 ? totalExpenses : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Distribution',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),
        _buildDistributionBar(
          context,
          label: 'Salaries',
          amount: salaries,
          percentage: salaries / denom,
          color: const Color(0xFF795548),
        ),
        const SizedBox(height: 10),
        _buildDistributionBar(
          context,
          label: 'Fertilizers',
          amount: fertilizers,
          percentage: fertilizers / denom,
          color: const Color(0xFF1976D2),
        ),
        const SizedBox(height: 10),
        _buildDistributionBar(
          context,
          label: 'Other Operations',
          amount: otherExpenses,
          percentage: otherExpenses / denom,
          color: const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildSalaryDistribution(
    BuildContext context,
    double totalSalary,
    double workerSalary,
    double managerSalary,
  ) {
    final theme = Theme.of(context);
    final denom = totalSalary > 0 ? totalSalary : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salary Distribution',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),
        _buildDistributionBar(
          context,
          label: 'Worker Salaries',
          amount: workerSalary,
          percentage: workerSalary / denom,
          color: const Color(0xFF795548),
        ),
        const SizedBox(height: 10),
        _buildDistributionBar(
          context,
          label: 'Manager Told Salary',
          amount: managerSalary,
          percentage: managerSalary / denom,
          color: const Color(0xFF673AB7),
        ),
      ],
    );
  }

  Widget _buildDistributionBar(
    BuildContext context, {
    required String label,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              '₹${amount.toStringAsFixed(0)} (${(percentage * 100).toStringAsFixed(0)}%)',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              color.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String searchHint,
    required String searchVal,
    required ValueChanged<String> onSearchChanged,
    required int recordsCount,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Local Search bar
            TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            recordsCount == 0
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No matching records found in range.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : child,
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(List<RecentActivityItem> latestActivities, BuildContext context) {
    final theme = Theme.of(context);
    if (latestActivities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('No activities logged in selected period.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: latestActivities.map((activity) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(activity.icon, size: 14, color: theme.colorScheme.primary),
                  ),
                  Container(
                    width: 2,
                    height: 35,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activity.module,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${activity.date} • ${activity.time}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  // List / Table renderers
  Widget _buildIncomeList(List<EstateIncomeModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_incomeSearch.isEmpty) return true;
      final q = _incomeSearch.toLowerCase();
      return item.productName.toLowerCase().contains(q) || item.category.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Green Qty')),
          DataColumn(label: Text('Dry Qty')),
          DataColumn(label: Text('Percent')),
          DataColumn(label: Text('Rate')),
          DataColumn(label: Text('Total')),
        ],
        rows: filtered.map((item) {
          final isCardamom = item.category.toLowerCase() == 'cardamom';
          return DataRow(cells: [
            DataCell(Text(_formatPrettyDate(item.date.toString().split(' ')[0]))),
            DataCell(Text(item.category)),
            DataCell(Text(item.productName)),
            DataCell(Text('${item.quantity} ${item.unit}')),
            DataCell(Text(isCardamom ? '${item.greenQuantity ?? 0.0} ${item.unit}' : '-')),
            DataCell(Text(isCardamom ? '${item.dryQuantity ?? 0.0} ${item.unit}' : '-')),
            DataCell(Text(isCardamom ? '${item.percent?.toStringAsFixed(2) ?? "0.00"}%' : '-')),
            DataCell(Text('₹${item.pricePerUnit}')),
            DataCell(Text('₹${item.totalAmount.toStringAsFixed(2)}')),
          ]);
        }).toList(),
      );
    }

    return Column(
      children: filtered.map((item) {
        final isCardamom = item.category.toLowerCase() == 'cardamom';
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              isCardamom
                  ? '${item.category} • ${_formatPrettyDate(item.date.toString().split(' ')[0])}\n'
                      'Green: ${item.greenQuantity ?? 0.0} ${item.unit} • Dry: ${item.dryQuantity ?? 0.0} ${item.unit}\n'
                      'Yield: ${item.percent?.toStringAsFixed(2) ?? "0.00"}% • Rate: ₹${item.pricePerUnit.toStringAsFixed(2)}/Kg'
                  : '${item.category} • ${_formatPrettyDate(item.date.toString().split(' ')[0])}\n'
                      'Qty: ${item.quantity} ${item.unit} • Rate: ₹${item.pricePerUnit.toStringAsFixed(2)}',
            ),
            isThreeLine: true,
            trailing: Text(
              '₹${item.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSalaryList(List<SalaryModel> list, Map<String, String> workerMap, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      final name = workerMap[item.workerId] ?? '';
      if (_salarySearch.isEmpty) return true;
      final q = _salarySearch.toLowerCase();
      return name.toLowerCase().contains(q) || item.period.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Worker')),
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('Salary')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Paid Date')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(workerMap[item.workerId] ?? 'Unknown')),
          DataCell(Text(item.period)),
          DataCell(Text('₹${item.totalSalary.toStringAsFixed(2)}')),
          DataCell(Text(item.paymentStatus.toUpperCase())),
          DataCell(Text(item.paymentDate != null ? _formatPrettyDate(item.paymentDate!) : '-')),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(workerMap[item.workerId] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item.period),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${item.totalSalary.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(item.paymentStatus.toUpperCase(), style: TextStyle(fontSize: 10, color: item.paymentStatus == 'paid' ? AppColors.primary : AppColors.error)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildManagerSalaryList(List<ManagerSalaryModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_managerSalarySearch.isEmpty) return true;
      final q = _managerSalarySearch.toLowerCase();
      return item.fromDate.contains(q) || item.toDate.contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('From Date')),
          DataColumn(label: Text('To Date')),
          DataColumn(label: Text('Weekly Salary')),
          DataColumn(label: Text('Created Date')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.fromDate))),
          DataCell(Text(_formatPrettyDate(item.toDate))),
          DataCell(Text('₹${item.weeklySalary.toStringAsFixed(2)}')),
          DataCell(Text(_formatPrettyDate(item.createdDate))),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text('Weekly Salary: ₹${item.weeklySalary.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Period: ${_formatPrettyDate(item.fromDate)} - ${_formatPrettyDate(item.toDate)}'),
          trailing: Text(
            _formatPrettyDate(item.createdDate),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildExpenseList(List<WeeklyExpenseModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_expenseSearch.isEmpty) return true;
      final q = _expenseSearch.toLowerCase();
      return item.category.toLowerCase().contains(q) || (item.notes ?? '').toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Notes')),
          DataColumn(label: Text('Amount')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text(item.category)),
          DataCell(Text(item.notes ?? '-')),
          DataCell(Text('₹${item.amount.toStringAsFixed(2)}')),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${item.notes ?? ''} • ${_formatPrettyDate(item.date)}'),
          trailing: Text('₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        ),
      )).toList(),
    );
  }

  Widget _buildPurchaseList(List<FertilizerModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_purchaseSearch.isEmpty) return true;
      final q = _purchaseSearch.toLowerCase();
      return item.name.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Fertilizer')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Total')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text(item.name)),
          DataCell(Text('${item.initialStock} Bags')),
          DataCell(Text('₹${item.price.toStringAsFixed(2)}')),
          DataCell(Text('₹${item.totalPrice.toStringAsFixed(2)}')),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${item.initialStock} Bags • ${_formatPrettyDate(item.date)}'),
          trailing: Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildUsageList(List<FertilizerUsageModel> list, Map<String, String> fertMap, Map<String, double> stockMap, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      final name = fertMap[item.fertilizerId] ?? '';
      if (_usageSearch.isEmpty) return true;
      final q = _usageSearch.toLowerCase();
      return name.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Fertilizer')),
          DataColumn(label: Text('Bags Used')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text(fertMap[item.fertilizerId] ?? 'Unknown')),
          DataCell(Text('${_formatBags(item.bagsUsed)} Bags')),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(fertMap[item.fertilizerId] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Used: ${_formatBags(item.bagsUsed)} Bags • ${_formatPrettyDate(item.date)}'),
        ),
      )).toList(),
    );
  }

  Widget _buildTreeCountList(List<TreeCountModel> list, Map<String, int> ledgerMap, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_treeCountSearch.isEmpty) return true;
      final q = _treeCountSearch.toLowerCase();
      return item.treeName.toLowerCase().contains(q) || item.plotName.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date Recorded')),
          DataColumn(label: Text('Tree Name')),
          DataColumn(label: Text('Plot')),
          DataColumn(label: Text('Current Count')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text(item.treeName)),
          DataCell(Text(item.plotName)),
          DataCell(Text('${ledgerMap[item.id] ?? item.initialCount} Trees')),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(item.treeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Plot: ${item.plotName} • Recorded: ${_formatPrettyDate(item.date)}'),
          trailing: Text('${ledgerMap[item.id] ?? item.initialCount} Trees', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildTreeCuttingList(List<TreeCuttingModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_treeCuttingSearch.isEmpty) return true;
      final q = _treeCuttingSearch.toLowerCase();
      return (item.treeName ?? '').toLowerCase().contains(q) || (item.placeName ?? '').toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const Text('No records match query.');

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date Cut')),
          DataColumn(label: Text('Tree Name')),
          DataColumn(label: Text('Place')),
          DataColumn(label: Text('Qty Cut')),
          DataColumn(label: Text('Price/Tree')),
          DataColumn(label: Text('Total Revenue')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text(item.treeName ?? '-')),
          DataCell(Text(item.placeName ?? '-')),
          DataCell(Text(item.numberOfTrees != null ? '${item.numberOfTrees} Trees' : '-')),
          DataCell(Text(item.pricePerTree != null ? '₹${item.pricePerTree!.toStringAsFixed(2)}' : '-')),
          DataCell(Text('₹${item.totalAmount.toStringAsFixed(2)}')),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(item.treeName ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Place: ${item.placeName ?? '-'} • ${item.numberOfTrees != null ? '${item.numberOfTrees} Cut' : 'Cut: -'} ${item.pricePerTree != null ? '@ ₹${item.pricePerTree!.toStringAsFixed(2)}' : ''}'),
          trailing: Text('₹${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
      )).toList(),
    );
  }

  Widget _buildOrganicFertilizerList(List<OrganicFertilizerModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_organicFertilizerSearch.isEmpty) return true;
      final q = _organicFertilizerSearch.toLowerCase();
      return item.name.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No records match query.'),
      );
    }

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Organic Fertilizer Name')),
          DataColumn(label: Text('Loads')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Price')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatLoads(item.loads))),
          DataCell(Text(item.unit)),
          DataCell(Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Loads: ${_formatLoads(item.loads)} (${item.unit}) • Purchased: ${_formatPrettyDate(item.date)}'),
          trailing: Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
      )).toList(),
    );
  }

  Widget _buildAttendanceList(List<AttendanceModel> list, bool isDesktop) {
    final theme = Theme.of(context);
    final filtered = list.where((item) {
      if (_attendanceSearch.isEmpty) return true;
      final q = _attendanceSearch.toLowerCase();
      return item.date.contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No records match query.'),
      );
    }

    if (isDesktop) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Total Workers')),
          DataColumn(label: Text('Present')),
          DataColumn(label: Text('Absent')),
        ],
        rows: filtered.map((item) => DataRow(cells: [
          DataCell(Text(_formatPrettyDate(item.date))),
          DataCell(Text('${item.totalWorkers}')),
          DataCell(Text('${item.presentCount}', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
          DataCell(Text('${item.absentCount}', style: const TextStyle(color: Color(0xFFD32F2F)))),
        ])).toList(),
      );
    }

    return Column(
      children: filtered.map((item) => Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text('Attendance on ${_formatPrettyDate(item.date)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Present: ${item.presentCount} • Absent: ${item.absentCount}'),
          trailing: Text('${item.totalWorkers} Workers'),
        ),
      )).toList(),
    );
  }
}
