import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/extensions/responsive_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../farm/models/farm_income_model.dart';
import '../../farm/models/farm_expense_model.dart';
import '../../farm/models/farm_fertilizer_model.dart';
import '../../farm/models/farm_organic_fertilizer_model.dart';
import '../../farm/models/farm_fertilizer_usage_model.dart';
import '../../farm/models/farm_salary_model.dart';
import '../../farm/providers/farm_income_provider.dart';
import '../../farm/providers/farm_expense_provider.dart';
import '../../farm/providers/farm_fertilizer_provider.dart';
import '../../farm/providers/farm_salary_provider.dart';
import '../utils/farm_report_export_helper.dart';

class FarmReportDashboardScreen extends ConsumerStatefulWidget {
  const FarmReportDashboardScreen({super.key});

  @override
  ConsumerState<FarmReportDashboardScreen> createState() => _FarmReportDashboardScreenState();
}

class _FarmReportDashboardScreenState extends ConsumerState<FarmReportDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDateRangeType = 'This Month';
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEndDate = DateTime.now();

  final List<String> _dateRangeTypes = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'Custom Date Range',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedDateRangeType) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'This Year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Custom Date Range':
      default:
        return DateTimeRange(
          start: DateTime(_customStartDate.year, _customStartDate.month, _customStartDate.day),
          end: DateTime(_customEndDate.year, _customEndDate.month, _customEndDate.day, 23, 59, 59),
        );
    }
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  Future<void> _selectCustomDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _customStartDate : _customEndDate,
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

  String _formatPrettyDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }


  String _formatDecimal(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  void _exportReport({
    required bool isPdf,
    required String periodText,
    required Map<String, String> summaryMap,
    required List<FarmIncomeModel> filteredIncomes,
    required List<FarmExpenseModel> filteredExpenses,
    required List<FarmSalaryModel> filteredSalaries,
    required List<FarmFertilizerModel> chemicalPurchases,
    required List<FarmOrganicFertilizerModel> organicPurchases,
    required List<FarmFertilizerUsageModel> chemicalUsages,
    required Map<String, String> chemNames,
    required Map<String, String> orgNames,
  }) async {
    if (isPdf) {
      await FarmReportExportHelper.sharePdf(
        dateRange: periodText,
        summary: summaryMap,
        incomeList: filteredIncomes,
        expenseList: filteredExpenses,
        salaryList: filteredSalaries,
        chemicalPurchases: chemicalPurchases,
        organicPurchases: organicPurchases,
        chemicalUsages: chemicalUsages,
        chemNames: chemNames,
        orgNames: orgNames,
      );
    } else {
      await FarmReportExportHelper.shareExcel(
        dateRange: periodText,
        summary: summaryMap,
        incomeList: filteredIncomes,
        expenseList: filteredExpenses,
        salaryList: filteredSalaries,
        chemicalPurchases: chemicalPurchases,
        organicPurchases: organicPurchases,
        chemicalUsages: chemicalUsages,
        chemNames: chemNames,
        orgNames: orgNames,
      );
    }
  }

  // Helper to group transactions into week slots
  List<Map<String, dynamic>> _groupByWeek({
    required DateTime start,
    required DateTime end,
    required List<FarmIncomeModel> incomes,
    required List<FarmExpenseModel> expenses,
    required List<FarmSalaryModel> salaries,
    required List<FarmFertilizerModel> chemicalPurchases,
    required List<FarmOrganicFertilizerModel> organicPurchases,
  }) {
    final List<Map<String, dynamic>> weeklyGroups = [];
    DateTime currentStart = start;

    while (currentStart.isBefore(end)) {
      DateTime currentEnd = currentStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      if (currentEnd.isAfter(end)) {
        currentEnd = end;
      }

      final weekIncomes = incomes.where((item) => _isWithinRange(item.date, currentStart, currentEnd)).toList();
      final weekExpenses = expenses.where((item) => _isWithinRange(item.date, currentStart, currentEnd)).toList();
      final weekSalaries = salaries.where((item) => _isWithinRange(item.fromDate, currentStart, currentEnd)).toList();
      final weekChem = chemicalPurchases.where((item) => _isWithinRange(DateTime.parse(item.date), currentStart, currentEnd)).toList();
      final weekOrg = organicPurchases.where((item) => _isWithinRange(DateTime.parse(item.date), currentStart, currentEnd)).toList();

      double incSum = weekIncomes.fold(0.0, (prev, e) => prev + e.totalAmount);
      double expSum = weekExpenses.fold(0.0, (prev, e) => prev + e.amount);
      double salSum = weekSalaries.fold(0.0, (prev, e) => prev + e.salaryAmount);
      double chemSum = weekChem.fold(0.0, (prev, e) => prev + e.price);
      double orgSum = weekOrg.fold(0.0, (prev, e) => prev + e.price);

      final double totalExp = expSum + salSum + chemSum + orgSum;
      final double profit = incSum - totalExp;

      if (weekIncomes.isNotEmpty || weekExpenses.isNotEmpty || weekSalaries.isNotEmpty || weekChem.isNotEmpty || weekOrg.isNotEmpty) {
        weeklyGroups.add({
          'start': currentStart,
          'end': currentEnd,
          'income': incSum,
          'expense': expSum,
          'salary': salSum,
          'fertilizer': chemSum + orgSum,
          'profit': profit,
          'incomesList': weekIncomes,
          'expensesList': weekExpenses,
          'salariesList': weekSalaries,
        });
      }

      currentStart = currentStart.add(const Duration(days: 7));
    }

    // Sort weeks descending
    weeklyGroups.sort((a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));
    return weeklyGroups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final incomesAsync = ref.watch(farmIncomeListProvider);
    final expensesAsync = ref.watch(farmExpenseListProvider);
    final salariesAsync = ref.watch(farmSalaryListProvider);
    final chemInvsAsync = ref.watch(farmChemicalInventoryProvider);
    final orgInvsAsync = ref.watch(farmOrganicInventoryProvider);
    final chemUsagesAsync = ref.watch(farmChemicalUsagesProvider);

    final isLoading = incomesAsync.isLoading ||
        expensesAsync.isLoading ||
        salariesAsync.isLoading ||
        chemInvsAsync.isLoading ||
        orgInvsAsync.isLoading ||
        chemUsagesAsync.isLoading;

    final hasError = incomesAsync.hasError ||
        expensesAsync.hasError ||
        salariesAsync.hasError ||
        chemInvsAsync.hasError ||
        orgInvsAsync.hasError ||
        chemUsagesAsync.hasError;

    if (isLoading) {
      return const Scaffold(body: LoadingIndicator(message: 'Loading farm reports...'));
    }

    if (hasError) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Error Loading Reports',
          description: 'An error occurred while loading farm reports.',
          actionLabel: 'Retry',
          onActionPressed: () {
            ref.invalidate(farmIncomeListProvider);
            ref.invalidate(farmExpenseListProvider);
            ref.invalidate(farmSalaryListProvider);
            ref.invalidate(farmChemicalInventoryProvider);
            ref.invalidate(farmOrganicInventoryProvider);
            ref.invalidate(farmChemicalUsagesProvider);
          },
        ),
      );
    }

    final incomes = incomesAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];
    final salaries = salariesAsync.value ?? [];
    final chemInvs = chemInvsAsync.value ?? [];
    final orgInvs = orgInvsAsync.value ?? [];
    final chemUsages = chemUsagesAsync.value ?? [];

    final Map<String, String> chemNames = {for (var f in chemInvs) f.id: f.name};
    final Map<String, String> orgNames = {for (var o in orgInvs) o.id: o.name};

    // Apply Date Filters
    final range = _getDateRange();
    final start = range.start;
    final end = range.end;

    final filteredIncomes = incomes.where((item) => _isWithinRange(item.date, start, end)).toList();
    final filteredExpenses = expenses.where((item) => _isWithinRange(item.date, start, end)).toList();
    final filteredSalaries = salaries.where((item) => _isWithinRange(item.fromDate, start, end)).toList();
    final filteredChemInvs = chemInvs.where((item) => _isWithinRange(DateTime.parse(item.date), start, end)).toList();
    final filteredOrgInvs = orgInvs.where((item) => _isWithinRange(DateTime.parse(item.date), start, end)).toList();
    final filteredChemUsages = chemUsages.where((item) => _isWithinRange(DateTime.parse(item.date), start, end)).toList();

    // Financial calculations
    double totalIncome = 0.0;
    for (final item in filteredIncomes) {
      totalIncome += item.totalAmount;
    }

    double generalExpenses = 0.0;
    for (final item in filteredExpenses) {
      generalExpenses += item.amount;
    }

    double totalSalary = 0.0;
    for (final item in filteredSalaries) {
      totalSalary += item.salaryAmount;
    }

    double chemicalPurchasesCost = 0.0;
    for (final item in filteredChemInvs) {
      chemicalPurchasesCost += item.price;
    }

    double organicPurchasesCost = 0.0;
    for (final item in filteredOrgInvs) {
      organicPurchasesCost += item.price;
    }

    final double totalFertilizer = chemicalPurchasesCost + organicPurchasesCost;
    final double combinedExpenses = generalExpenses + totalSalary + totalFertilizer;
    final double netProfit = totalIncome - combinedExpenses;

    final periodText = _selectedDateRangeType == 'Custom Date Range'
        ? '${_formatPrettyDate(_customStartDate)} - ${_formatPrettyDate(_customEndDate)}'
        : _selectedDateRangeType;

    final summaryMap = {
      'Total Income': '₹${totalIncome.toStringAsFixed(2)}',
      'Total Expenses': '₹${generalExpenses.toStringAsFixed(2)}',
      'Total Salary': '₹${totalSalary.toStringAsFixed(2)}',
      'Total Fertilizer Expenses': '₹${totalFertilizer.toStringAsFixed(2)}',
      'Net Profit': '₹${netProfit.toStringAsFixed(2)}',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Farm PDF',
            onPressed: () => _exportReport(
              isPdf: true,
              periodText: periodText,
              summaryMap: summaryMap,
              filteredIncomes: filteredIncomes,
              filteredExpenses: filteredExpenses,
              filteredSalaries: filteredSalaries,
              chemicalPurchases: filteredChemInvs,
              organicPurchases: filteredOrgInvs,
              chemicalUsages: filteredChemUsages,
              chemNames: chemNames,
              orgNames: orgNames,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'Export Farm Excel',
            onPressed: () => _exportReport(
              isPdf: false,
              periodText: periodText,
              summaryMap: summaryMap,
              filteredIncomes: filteredIncomes,
              filteredExpenses: filteredExpenses,
              filteredSalaries: filteredSalaries,
              chemicalPurchases: filteredChemInvs,
              organicPurchases: filteredOrgInvs,
              chemicalUsages: filteredChemUsages,
              chemNames: chemNames,
              orgNames: orgNames,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Shared Date Filter at top of page body
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Select Date Filter',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dateRangeTypes.map((type) {
                        final isSelected = _selectedDateRangeType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedDateRangeType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedDateRangeType == 'Custom Date Range') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text('Start: ${_formatPrettyDate(_customStartDate)}'),
                              onPressed: () => _selectCustomDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text('End: ${_formatPrettyDate(_customEndDate)}'),
                              onPressed: () => _selectCustomDate(context, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Dashboard Overview
                  _buildDashboardTab(
                    context,
                    totalIncome: totalIncome,
                    totalExpenses: generalExpenses,
                    totalSalary: totalSalary,
                    totalFertilizer: totalFertilizer,
                    netProfit: netProfit,
                    filteredIncomes: filteredIncomes,
                    filteredExpenses: filteredExpenses,
                    filteredSalaries: filteredSalaries,
                    filteredChemInvs: filteredChemInvs,
                    filteredOrgInvs: filteredOrgInvs,
                    filteredChemUsages: filteredChemUsages,
                    chemNames: chemNames,
                    orgNames: orgNames,
                  ),

                  // Tab 2: Weekly Report
                  _buildWeeklyTab(
                    context,
                    start: start,
                    end: end,
                    incomes: filteredIncomes,
                    expenses: filteredExpenses,
                    salaries: filteredSalaries,
                    chemicalPurchases: filteredChemInvs,
                    organicPurchases: filteredOrgInvs,
                  ),

                  // Tab 3: Monthly Report
                  _buildMonthlyTab(
                    context,
                    totalIncome: totalIncome,
                    totalExpenses: generalExpenses,
                    totalSalary: totalSalary,
                    totalFertilizer: totalFertilizer,
                    netProfit: netProfit,
                    filteredIncomes: filteredIncomes,
                    filteredExpenses: filteredExpenses,
                    filteredSalaries: filteredSalaries,
                    filteredChemInvs: filteredChemInvs,
                    filteredOrgInvs: filteredOrgInvs,
                    filteredChemUsages: filteredChemUsages,
                  ),

                  // Tab 4: Yearly Report
                  _buildYearlyTab(
                    context,
                    totalIncome: totalIncome,
                    totalExpenses: generalExpenses,
                    totalSalary: totalSalary,
                    totalFertilizer: totalFertilizer,
                    netProfit: netProfit,
                    filteredIncomes: filteredIncomes,
                    filteredExpenses: filteredExpenses,
                    filteredChemInvs: filteredChemInvs,
                    filteredOrgInvs: filteredOrgInvs,
                    filteredChemUsages: filteredChemUsages,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 1: DASHBOARD OVERVIEW BUILDER
  // -----------------------------------------------------------------------------
  Widget _buildDashboardTab(
    BuildContext context, {
    required double totalIncome,
    required double totalExpenses,
    required double totalSalary,
    required double totalFertilizer,
    required double netProfit,
    required List<FarmIncomeModel> filteredIncomes,
    required List<FarmExpenseModel> filteredExpenses,
    required List<FarmSalaryModel> filteredSalaries,
    required List<FarmFertilizerModel> filteredChemInvs,
    required List<FarmOrganicFertilizerModel> filteredOrgInvs,
    required List<FarmFertilizerUsageModel> filteredChemUsages,
    required Map<String, String> chemNames,
    required Map<String, String> orgNames,
  }) {
    final theme = Theme.of(context);
    final double combinedExpenses = totalExpenses + totalSalary + totalFertilizer;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Panels
          GridView.count(
            crossAxisCount: context.isDesktop ? 3 : (context.isTablet ? 2 : 1),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.8,
            children: [
              _buildKPICard(context, 'Total Income', formatINR(totalIncome), Icons.trending_up, Colors.green),
              _buildKPICard(context, 'Total Expenses', formatINR(combinedExpenses), Icons.trending_down, Colors.red),
              _buildKPICard(
                context,
                'Net Profit',
                formatINR(netProfit),
                Icons.account_balance_wallet,
                netProfit >= 0 ? AppColors.primary : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detailed Records Sections (Expandable)
          Text('Detailed Transaction Logs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Section 1: Income
                ExpansionTile(
                  leading: const Icon(Icons.attach_money, color: Colors.green),
                  title: Text('Farm Income (${filteredIncomes.length} records)'),
                  children: [
                    if (filteredIncomes.isEmpty)
                      const Padding(padding: EdgeInsets.all(16.0), child: Text('No income logs in this period'))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredIncomes.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = filteredIncomes[idx];
                          return ListTile(
                            title: Text('${item.productName} Sale'),
                            subtitle: Text(_formatPrettyDate(item.date)),
                            trailing: Text(formatINR(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          );
                        },
                      ),
                  ],
                ),
                const Divider(height: 1),

                // Section 2: General Expenses
                ExpansionTile(
                  leading: const Icon(Icons.money_off, color: Colors.red),
                  title: Text('Farm Expenses (${filteredExpenses.length} records)'),
                  children: [
                    if (filteredExpenses.isEmpty)
                      const Padding(padding: EdgeInsets.all(16.0), child: Text('No expense logs in this period'))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredExpenses.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = filteredExpenses[idx];
                          final sub = item.subCategory != null ? ' (${item.subCategory})' : '';
                          return ListTile(
                            title: Text('${item.category} Expense$sub'),
                            subtitle: Text(_formatPrettyDate(item.date)),
                            trailing: Text(formatINR(item.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          );
                        },
                      ),
                  ],
                ),
                const Divider(height: 1),

                // Section 3: Farm Salary
                ExpansionTile(
                  leading: const Icon(Icons.payments, color: Colors.blue),
                  title: Text('Farm Salary (${filteredSalaries.length} records)'),
                  children: [
                    if (filteredSalaries.isEmpty)
                      const Padding(padding: EdgeInsets.all(16.0), child: Text('No salary logs in this period'))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSalaries.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = filteredSalaries[idx];
                          return ListTile(
                            title: Text(item.work),
                            subtitle: Text('${_formatPrettyDate(item.fromDate)} - ${_formatPrettyDate(item.toDate)} (${item.numberOfPersons} workers)'),
                            trailing: Text(formatINR(item.salaryAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          );
                        },
                      ),
                  ],
                ),
                const Divider(height: 1),

                // Section 4: Fertilizer purchases & usage logs
                ExpansionTile(
                  leading: const Icon(Icons.grass, color: Colors.orange),
                  title: Text('Fertilizer Records (${filteredChemInvs.length + filteredOrgInvs.length + filteredChemUsages.length} records)'),
                  children: [
                    if (filteredChemInvs.isEmpty && filteredOrgInvs.isEmpty && filteredChemUsages.isEmpty)
                      const Padding(padding: EdgeInsets.all(16.0), child: Text('No fertilizer logs in this period'))
                    else ...[
                      if (filteredChemInvs.isNotEmpty) ...[
                        ListTile(title: Text('Chemical Purchases (${filteredChemInvs.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredChemInvs.length,
                          itemBuilder: (context, idx) {
                            final item = filteredChemInvs[idx];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('Purchased ${_formatPrettyDate(DateTime.parse(item.date))} (${_formatDecimal(item.initialStock)} Bags)'),
                              trailing: Text(formatINR(item.price), style: const TextStyle(color: Colors.red)),
                            );
                          },
                        ),
                      ],
                      if (filteredOrgInvs.isNotEmpty) ...[
                        ListTile(title: Text('Organic Purchases (${filteredOrgInvs.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredOrgInvs.length,
                          itemBuilder: (context, idx) {
                            final item = filteredOrgInvs[idx];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('Purchased ${_formatPrettyDate(DateTime.parse(item.date))} (${_formatDecimal(item.loads)} loads)'),
                              trailing: Text(formatINR(item.price), style: const TextStyle(color: Colors.red)),
                            );
                          },
                        ),
                      ],
                      if (filteredChemUsages.isNotEmpty) ...[
                        ListTile(title: Text('Chemical Stock Usages (${filteredChemUsages.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredChemUsages.length,
                          itemBuilder: (context, idx) {
                            final item = filteredChemUsages[idx];
                            final name = chemNames[item.fertilizerId] ?? 'Unknown';
                            return ListTile(
                              title: Text('Used $name'),
                              subtitle: Text('Applied on ${_formatPrettyDate(DateTime.parse(item.date))}'),
                              trailing: Text('${_formatDecimal(item.bagsUsed)} Bags', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 2: WEEKLY REPORT BUILDER
  // -----------------------------------------------------------------------------
  Widget _buildWeeklyTab(
    BuildContext context, {
    required DateTime start,
    required DateTime end,
    required List<FarmIncomeModel> incomes,
    required List<FarmExpenseModel> expenses,
    required List<FarmSalaryModel> salaries,
    required List<FarmFertilizerModel> chemicalPurchases,
    required List<FarmOrganicFertilizerModel> organicPurchases,
  }) {
    final theme = Theme.of(context);
    final weeklyGroups = _groupByWeek(
      start: start,
      end: end,
      incomes: incomes,
      expenses: expenses,
      salaries: salaries,
      chemicalPurchases: chemicalPurchases,
      organicPurchases: organicPurchases,
    );

    if (weeklyGroups.isEmpty) {
      return const EmptyState(
        icon: Icons.date_range_outlined,
        title: 'No Weekly Data Available',
        description: 'Try widening your date filter period.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: weeklyGroups.length,
      itemBuilder: (context, index) {
        final group = weeklyGroups[index];
        final dtStart = group['start'] as DateTime;
        final dtEnd = group['end'] as DateTime;
        final double income = group['income'] as double;
        final double expense = group['expense'] as double;
        final double salary = group['salary'] as double;
        final double fertilizer = group['fertilizer'] as double;
        final double profit = group['profit'] as double;

        final weekIncomes = group['incomesList'] as List<FarmIncomeModel>;
        final weekExpenses = group['expensesList'] as List<FarmExpenseModel>;
        final weekSalaries = group['salariesList'] as List<FarmSalaryModel>;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              'Week: ${_formatPrettyDate(dtStart)} - ${_formatPrettyDate(dtEnd)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Net: ${formatINR(profit)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Row Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmallStatCard(context, 'Income', formatINR(income), Colors.green),
                        _buildSmallStatCard(context, 'General Exp', formatINR(expense), Colors.red),
                        _buildSmallStatCard(context, 'Salaries', formatINR(salary), Colors.blue),
                        _buildSmallStatCard(context, 'Fertilizer', formatINR(fertilizer), Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Weekly Logs Detailed Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),

                    if (weekIncomes.isNotEmpty) ...[
                      const Text('Incomes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                      ...weekIncomes.map((item) => ListTile(
                            dense: true,
                            title: Text('${item.productName} Sale'),
                            trailing: Text(formatINR(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          )),
                    ],
                    if (weekExpenses.isNotEmpty) ...[
                      const Text('General Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                      ...weekExpenses.map((item) => ListTile(
                            dense: true,
                            title: Text(item.category),
                            trailing: Text(formatINR(item.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          )),
                    ],
                    if (weekSalaries.isNotEmpty) ...[
                      const Text('Salaries Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      ...weekSalaries.map((item) => ListTile(
                            dense: true,
                            title: Text(item.work),
                            trailing: Text(formatINR(item.salaryAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallStatCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.05),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 3: MONTHLY REPORT BUILDER
  // -----------------------------------------------------------------------------
  Widget _buildMonthlyTab(
    BuildContext context, {
    required double totalIncome,
    required double totalExpenses,
    required double totalSalary,
    required double totalFertilizer,
    required double netProfit,
    required List<FarmIncomeModel> filteredIncomes,
    required List<FarmExpenseModel> filteredExpenses,
    required List<FarmSalaryModel> filteredSalaries,
    required List<FarmFertilizerModel> filteredChemInvs,
    required List<FarmOrganicFertilizerModel> filteredOrgInvs,
    required List<FarmFertilizerUsageModel> filteredChemUsages,
  }) {
    final theme = Theme.of(context);
    final double combinedExpenses = totalExpenses + totalSalary + totalFertilizer;

    // Chemical Fertilizer stock calculations
    double stockAdded = 0.0;
    double stockUsed = 0.0;
    double remainingStock = 0.0;

    for (final item in filteredChemInvs) {
      stockAdded += item.initialStock;
    }
    for (final item in filteredChemUsages) {
      stockUsed += item.bagsUsed;
    }
    remainingStock = stockAdded - stockUsed;

    // Organic Fertilizer calculations
    double organicLoads = 0.0;
    for (final item in filteredOrgInvs) {
      organicLoads += item.loads;
    }

    // Work-wise salary breakdown
    final Map<String, double> workBreakdown = {};
    int totalWorkersCount = 0;
    for (final item in filteredSalaries) {
      totalWorkersCount += item.numberOfPersons;
      final key = item.work.trim();
      workBreakdown[key] = (workBreakdown[key] ?? 0.0) + item.salaryAmount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profit & Loss Card
          Text('1. Profit & Loss Statement', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryRowPL('Total Revenues (Incomes)', totalIncome, theme, isIncome: true),
                  const Divider(),
                  _buildSummaryRowPL('Total Expenditures (Expenses)', combinedExpenses, theme, isIncome: false),
                  const Divider(height: 24, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        formatINR(netProfit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: netProfit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Fertilizer Summary Card
          Text('2. Fertilizer Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chemical Fertilizer (Bags)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricBox('Purchases', '${filteredChemInvs.length} Records'),
                      _buildMetricBox('Stock Added', '${_formatDecimal(stockAdded)} Bags'),
                      _buildMetricBox('Stock Used', '${_formatDecimal(stockUsed)} Bags'),
                      _buildMetricBox('Remaining', '${_formatDecimal(remainingStock)} Bags', highlightColor: Colors.blue),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Organic Fertilizer (Loads)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricBox('Purchases', '${filteredOrgInvs.length} Records'),
                      _buildMetricBox('Total Loads', '${_formatDecimal(organicLoads)} Loads', highlightColor: Colors.orange),
                      const Spacer(),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Labour Summary Card
          Text('3. Labour Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricBox('Salary Paid', formatINR(totalSalary), highlightColor: AppColors.primary),
                      _buildMetricBox('Entries Count', '${filteredSalaries.length} Logs'),
                      _buildMetricBox('Total Workers', '$totalWorkersCount Persons'),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Work-wise Salary Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (workBreakdown.isEmpty)
                    const Text('No labour logs available.', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: workBreakdown.length,
                      itemBuilder: (context, idx) {
                        final key = workBreakdown.keys.elementAt(idx);
                        final val = workBreakdown[key]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(key, style: const TextStyle(color: AppColors.textSecondary)),
                              Text(formatINR(val), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, {Color? highlightColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlightColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowPL(String label, double amount, ThemeData theme, {required bool isIncome}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            formatINR(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 4: YEARLY REPORT BUILDER
  // -----------------------------------------------------------------------------
  Widget _buildYearlyTab(
    BuildContext context, {
    required double totalIncome,
    required double totalExpenses,
    required double totalSalary,
    required double totalFertilizer,
    required double netProfit,
    required List<FarmIncomeModel> filteredIncomes,
    required List<FarmExpenseModel> filteredExpenses,
    required List<FarmFertilizerModel> filteredChemInvs,
    required List<FarmOrganicFertilizerModel> filteredOrgInvs,
    required List<FarmFertilizerUsageModel> filteredChemUsages,
  }) {
    final theme = Theme.of(context);

    // Income breakdown
    double coconutInc = 0.0;
    double mangoInc = 0.0;
    double milkInc = 0.0;
    double otherInc = 0.0;

    for (final item in filteredIncomes) {
      final cat = item.category.toLowerCase();
      if (cat == 'coconut') {
        coconutInc += item.totalAmount;
      } else if (cat == 'mango') {
        mangoInc += item.totalAmount;
      } else if (cat == 'milk') {
        milkInc += item.totalAmount;
      } else {
        otherInc += item.totalAmount;
      }
    }

    // Expense breakdown
    double coconutExp = 0.0;
    double milkExp = 0.0;
    double mangoExp = 0.0;
    double otherExp = 0.0;

    for (final item in filteredExpenses) {
      final cat = item.category.toLowerCase();
      if (cat == 'coconut') {
        coconutExp += item.amount;
      } else if (cat == 'milk') {
        milkExp += item.amount;
      } else if (cat == 'mango') {
        mangoExp += item.amount;
      } else {
        otherExp += item.amount;
      }
    }

    // Fertilizer calculations
    double chemAdded = 0.0;
    double chemUsed = 0.0;
    for (final item in filteredChemInvs) {
      chemAdded += item.initialStock;
    }
    for (final item in filteredChemUsages) {
      chemUsed += item.bagsUsed;
    }
    final chemRemaining = chemAdded - chemUsed;

    double orgLoads = 0.0;
    for (final item in filteredOrgInvs) {
      orgLoads += item.loads;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'FARM ANNUAL FINANCIAL REPORT',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 1. Income Summary Table
          _buildYearlySectionHeader('1. Income Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryRow('Coconut Income', coconutInc, theme),
                  const Divider(),
                  _buildSummaryRow('Mango Income', mangoInc, theme),
                  const Divider(),
                  _buildSummaryRow('Milk Income', milkInc, theme),
                  const Divider(),
                  _buildSummaryRow('Others Income', otherInc, theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Expense Summary Table
          _buildYearlySectionHeader('2. Expense Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryRow('Coconut Expenses', coconutExp, theme),
                  const Divider(),
                  _buildSummaryRow('Milk Expenses', milkExp, theme),
                  const Divider(),
                  _buildSummaryRow('Mango Expenses', mangoExp, theme),
                  const Divider(),
                  _buildSummaryRow('Other Expenses', otherExp, theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Salary Summary
          _buildYearlySectionHeader('3. Salary Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSummaryRow('Total Farm Salary Paid', totalSalary, theme),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Fertilizer Summary Table
          _buildYearlySectionHeader('4. Fertilizer Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chemical Fertilizer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildDetailRowText('Purchased Stock', '${_formatDecimal(chemAdded)} Bags'),
                  _buildDetailRowText('Used Stock', '${_formatDecimal(chemUsed)} Bags'),
                  _buildDetailRowText('Remaining Stock', '${_formatDecimal(chemRemaining)} Bags'),
                  const Divider(height: 24),
                  const Text('Organic Fertilizer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildDetailRowText('Loads Manured', '${_formatDecimal(orgLoads)} Loads'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Profit & Loss Card
          _buildYearlySectionHeader('5. Profit & Loss Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryRowPL('Total Revenues', totalIncome, theme, isIncome: true),
                  const Divider(),
                  _buildSummaryRowPL('General Expenses', totalExpenses, theme, isIncome: false),
                  const Divider(),
                  _buildSummaryRowPL('Farm Salaries Paid', totalSalary, theme, isIncome: false),
                  const Divider(),
                  _buildSummaryRowPL('Fertilizer Purchases', totalFertilizer, theme, isIncome: false),
                  const Divider(height: 24, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NET PROFIT (REVENUE - EXPENSES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        formatINR(netProfit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: netProfit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
      ),
    );
  }

  Widget _buildDetailRowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // REUSABLE BUILD WIDGETS
  // -----------------------------------------------------------------------------
  Widget _buildKPICard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            formatINR(amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
