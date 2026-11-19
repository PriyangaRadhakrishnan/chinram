import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/authentication/screens/splash_screen.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/authentication/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/dashboard_shell.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/estate/screens/estate_screen.dart';
import '../features/estate/screens/estate_category_list_screen.dart';
import '../features/estate/screens/estate_product_list_screen.dart';
import '../features/estate/screens/estate_income_form_screen.dart';
import '../features/estate/screens/estate_income_history_screen.dart';
import '../features/estate/screens/estate_income_detail_screen.dart';
import '../features/estate/screens/worker_list_screen.dart';
import '../features/estate/screens/worker_form_screen.dart';
import '../features/estate/screens/worker_detail_screen.dart';
import '../features/estate/screens/attendance_screen.dart';
import '../features/estate/screens/attendance_history_screen.dart';
import '../features/estate/screens/attendance_detail_screen.dart';
import '../features/estate/screens/salary_history_screen.dart';
import '../features/estate/screens/salary_configuration_screen.dart';
import '../features/estate/screens/salary_form_screen.dart';
import '../features/estate/screens/salary_period_details_screen.dart';
import '../features/estate/screens/salary_detail_screen.dart';
import '../features/estate/screens/manager_salary_form_screen.dart';
import '../features/estate/screens/manager_salary_detail_screen.dart';
import '../features/estate/screens/expense_history_screen.dart';
import '../features/estate/screens/expense_form_screen.dart';
import '../features/estate/screens/expense_detail_screen.dart';
import '../features/estate/screens/fertilizer_dashboard_screen.dart';
import '../features/estate/screens/fertilizer_form_screen.dart';
import '../features/estate/screens/fertilizer_usage_form_screen.dart';
import '../features/estate/screens/fertilizer_detail_screen.dart';
import '../features/estate/screens/organic_fertilizer_detail_screen.dart';
import '../features/estate/screens/tree_count_history_screen.dart';
import '../features/estate/screens/tree_count_form_screen.dart';
import '../features/estate/screens/tree_count_detail_screen.dart';
import '../features/estate/screens/tree_cutting_history_screen.dart';
import '../features/estate/screens/tree_cutting_form_screen.dart';
import '../features/estate/screens/tree_cutting_detail_screen.dart';
import '../features/farm/screens/farm_screen.dart';
import '../features/farm/screens/farm_income_category_screen.dart';
import '../features/farm/screens/farm_income_history_screen.dart';
import '../features/farm/screens/farm_income_form_screen.dart';
import '../features/farm/screens/farm_income_detail_screen.dart';
import '../features/farm/screens/farm_expense_category_screen.dart';
import '../features/farm/screens/milk_expense_sections_screen.dart';
import '../features/farm/screens/farm_expense_history_screen.dart';
import '../features/farm/screens/farm_expense_form_screen.dart';
import '../features/farm/screens/farm_expense_detail_screen.dart';
import '../features/farm/screens/farm_fertilizer_dashboard_screen.dart';
import '../features/farm/screens/farm_fertilizer_usage_dashboard_screen.dart';
import '../features/farm/screens/farm_fertilizer_form_screen.dart';
import '../features/farm/screens/farm_organic_fertilizer_form_screen.dart';
import '../features/farm/screens/farm_fertilizer_usage_form_screen.dart';
import '../features/farm/screens/farm_fertilizer_detail_screens.dart';
import '../features/farm/screens/farm_salary_history_screen.dart';
import '../features/farm/screens/farm_salary_form_screen.dart';
import '../features/farm/screens/farm_salary_detail_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/reports/screens/farm_report_dashboard_screen.dart';
import '../features/dryer/screens/dryer_screen.dart';
import '../features/dryer/screens/dryer_add_form_screen.dart';
import '../features/dryer/screens/dryer_customer_detail_screen.dart';
import '../features/dryer/screens/dryer_customer_edit_screen.dart';
import '../features/dryer/screens/dryer_visit_detail_screen.dart';
import '../features/dryer/screens/dryer_visit_edit_screen.dart';
import '../features/dryer/screens/dryer_other_expenses_screen.dart';
import '../features/dryer/screens/dryer_expense_form_screen.dart';
import '../features/dryer/screens/dryer_expense_detail_screen.dart';
import '../features/estate/screens/report_dashboard_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/estate',
            builder: (context, state) => const EstateScreen(),
            routes: [
              GoRoute(
                path: 'income',
                builder: (context, state) => const EstateCategoryListScreen(),
              ),
              GoRoute(
                path: 'income/category/:catId/products',
                builder: (context, state) => EstateProductListScreen(
                  categoryId: state.pathParameters['catId']!,
                ),
              ),
              GoRoute(
                path: 'income/add',
                builder: (context, state) => EstateIncomeFormScreen(
                  category: state.uri.queryParameters['category'],
                  product: state.uri.queryParameters['product'],
                ),
              ),
              GoRoute(
                path: 'income/edit/:id',
                builder: (context, state) => EstateIncomeFormScreen(
                  incomeId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'income/detail/:id',
                builder: (context, state) => EstateIncomeDetailScreen(
                  incomeId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'income/history',
                builder: (context, state) => EstateIncomeHistoryScreen(
                  category: state.uri.queryParameters['category'] ?? '',
                  product: state.uri.queryParameters['product'] ?? '',
                ),
              ),
              GoRoute(
                path: 'workers',
                builder: (context, state) => const WorkerListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const WorkerFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => WorkerFormScreen(
                      workerId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => WorkerDetailScreen(
                      workerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'attendance',
                builder: (context, state) => const AttendanceScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const AttendanceHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'detail/:date',
                    builder: (context, state) => AttendanceDetailScreen(
                      date: state.pathParameters['date']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'salary',
                builder: (context, state) => const SalaryHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'config',
                    builder: (context, state) => const SalaryConfigurationScreen(),
                  ),
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const SalaryFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => SalaryFormScreen(
                      salaryId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'period/:period',
                    builder: (context, state) => SalaryPeriodDetailsScreen(
                      period: state.pathParameters['period']!,
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => SalaryDetailScreen(
                      salaryId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'manager/add',
                    builder: (context, state) => const ManagerSalaryFormScreen(),
                  ),
                  GoRoute(
                    path: 'manager/edit/:id',
                    builder: (context, state) => ManagerSalaryFormScreen(
                      managerSalaryId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'manager/detail/:id',
                    builder: (context, state) => ManagerSalaryDetailScreen(
                      managerSalaryId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'expenses',
                builder: (context, state) => const ExpenseHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const ExpenseFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => ExpenseFormScreen(
                      expenseId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => ExpenseDetailScreen(
                      expenseId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'fertilizer',
                builder: (context, state) => const FertilizerDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'inventory/add',
                    builder: (context, state) => FertilizerFormScreen(
                      initialTab: state.uri.queryParameters['tab'] == 'organic' ? 1 : 0,
                    ),
                  ),
                  GoRoute(
                    path: 'inventory/edit/:id',
                    builder: (context, state) => FertilizerFormScreen(
                      fertilizerId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'inventory/detail/:id',
                    builder: (context, state) => FertilizerDetailScreen(
                      id: state.pathParameters['id']!,
                      type: 'inventory',
                    ),
                  ),
                  GoRoute(
                    path: 'usage/add',
                    builder: (context, state) => const FertilizerUsageFormScreen(),
                  ),
                  GoRoute(
                    path: 'usage/edit/:id',
                    builder: (context, state) => FertilizerUsageFormScreen(
                      usageId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'usage/detail/:id',
                    builder: (context, state) => FertilizerDetailScreen(
                      id: state.pathParameters['id']!,
                      type: 'usage',
                    ),
                  ),
                  GoRoute(
                    path: 'organic/edit/:id',
                    builder: (context, state) => FertilizerFormScreen(
                      organicFertilizerId: state.pathParameters['id'],
                      initialTab: 1,
                    ),
                  ),
                  GoRoute(
                    path: 'organic/detail/:id',
                    builder: (context, state) => OrganicFertilizerDetailScreen(
                      organicId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'trees',
                builder: (context, state) => const TreeCountHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const TreeCountFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => TreeCountFormScreen(
                      treeCountId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => TreeCountDetailScreen(
                      recordId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'maravettu',
                builder: (context, state) => const TreeCuttingHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const TreeCuttingFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) => TreeCuttingFormScreen(
                      treeCuttingId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => TreeCuttingDetailScreen(
                      recordId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) => const ReportDashboardScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/farm',
            builder: (context, state) => const FarmScreen(),
            routes: [
              GoRoute(
                path: 'income',
                builder: (context, state) => const FarmIncomeCategoryScreen(),
              ),
              GoRoute(
                path: 'income/add',
                builder: (context, state) => FarmIncomeFormScreen(
                  category: state.uri.queryParameters['category'],
                ),
              ),
              GoRoute(
                path: 'income/edit/:id',
                builder: (context, state) => FarmIncomeFormScreen(
                  incomeId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'income/detail/:id',
                builder: (context, state) => FarmIncomeDetailScreen(
                  incomeId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'income/history',
                builder: (context, state) => FarmIncomeHistoryScreen(
                  category: state.uri.queryParameters['category'] ?? '',
                ),
              ),
              GoRoute(
                path: 'expenses',
                builder: (context, state) => const FarmExpenseCategoryScreen(),
              ),
              GoRoute(
                path: 'expenses/milk',
                builder: (context, state) => const MilkExpenseSectionsScreen(),
              ),
              GoRoute(
                path: 'expenses/history',
                builder: (context, state) => FarmExpenseHistoryScreen(
                  category: state.uri.queryParameters['category'] ?? '',
                  subCategory: state.uri.queryParameters['subCategory'],
                ),
              ),
              GoRoute(
                path: 'expenses/add',
                builder: (context, state) => FarmExpenseFormScreen(
                  category: state.uri.queryParameters['category'],
                  subCategory: state.uri.queryParameters['subCategory'],
                ),
              ),
              GoRoute(
                path: 'expenses/edit/:id',
                builder: (context, state) => FarmExpenseFormScreen(
                  expenseId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'expenses/detail/:id',
                builder: (context, state) => FarmExpenseDetailScreen(
                  expenseId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'salary',
                builder: (context, state) => const FarmSalaryHistoryScreen(),
              ),
              GoRoute(
                path: 'salary/add',
                builder: (context, state) => const FarmSalaryFormScreen(),
              ),
              GoRoute(
                path: 'salary/edit/:id',
                builder: (context, state) => FarmSalaryFormScreen(
                  salaryId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'salary/detail/:id',
                builder: (context, state) => FarmSalaryDetailScreen(
                  salaryId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) => const FarmReportDashboardScreen(),
              ),
              GoRoute(
                path: 'fertilizer',
                builder: (context, state) => const FarmFertilizerDashboardScreen(),
              ),
              GoRoute(
                path: 'fertilizer/add',
                builder: (context, state) => const FarmFertilizerFormScreen(),
              ),
              GoRoute(
                path: 'fertilizer/edit/:id',
                builder: (context, state) => FarmFertilizerFormScreen(
                  id: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'fertilizer/detail/:id',
                builder: (context, state) => FarmFertilizerDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'fertilizer/organic/add',
                builder: (context, state) => const FarmOrganicFertilizerFormScreen(),
              ),
              GoRoute(
                path: 'fertilizer/organic/edit/:id',
                builder: (context, state) => FarmOrganicFertilizerFormScreen(
                  id: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'fertilizer/organic/detail/:id',
                builder: (context, state) => FarmOrganicFertilizerDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'fertilizer/usage',
                builder: (context, state) => const FarmFertilizerUsageDashboardScreen(),
              ),
              GoRoute(
                path: 'fertilizer/usage/add',
                builder: (context, state) => const FarmFertilizerUsageFormScreen(),
              ),
              GoRoute(
                path: 'fertilizer/usage/edit/:id',
                builder: (context, state) => FarmFertilizerUsageFormScreen(
                  id: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'fertilizer/usage/detail/:id',
                builder: (context, state) => FarmFertilizerUsageDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/dryer',
            builder: (context, state) => const DryerScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => DryerAddFormScreen(
                  initialCustomerId: state.uri.queryParameters['customerId'],
                ),
              ),
              GoRoute(
                path: 'customer/:id',
                builder: (context, state) => DryerCustomerDetailScreen(
                  customerId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => DryerCustomerEditScreen(
                      customerId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'visit/:visitId',
                    builder: (context, state) => DryerVisitDetailScreen(
                      customerId: state.pathParameters['id']!,
                      visitId: state.pathParameters['visitId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => DryerVisitEditScreen(
                          customerId: state.pathParameters['id']!,
                          visitId: state.pathParameters['visitId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'expenses',
                builder: (context, state) => const DryerOtherExpensesScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const DryerExpenseFormScreen(),
                  ),
                  GoRoute(
                    path: 'detail/:expenseId',
                    builder: (context, state) => DryerExpenseDetailScreen(
                      expenseId: state.pathParameters['expenseId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:expenseId',
                    builder: (context, state) => DryerExpenseFormScreen(
                      expenseId: state.pathParameters['expenseId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
