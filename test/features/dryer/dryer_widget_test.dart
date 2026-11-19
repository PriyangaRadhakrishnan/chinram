import 'dart:async';

import 'package:chinram_app/features/dryer/models/dryer_customer_model.dart';
import 'package:chinram_app/features/dryer/models/dryer_visit_model.dart';
import 'package:chinram_app/features/dryer/providers/dryer_provider.dart';
import 'package:chinram_app/features/dryer/repositories/dryer_customer_repository.dart';
import 'package:chinram_app/features/dryer/repositories/dryer_visit_repository.dart';
import 'package:chinram_app/features/dryer/screens/dryer_add_form_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_customer_detail_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_customer_edit_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_visit_detail_screen.dart';
import 'package:chinram_app/features/dryer/screens/dryer_visit_edit_screen.dart';
import 'package:chinram_app/features/dryer/services/dryer_service.dart';
import 'package:chinram_app/features/dryer/utils/dryer_calculator.dart';
import 'package:chinram_app/features/dryer/widgets/dryer_info_widgets.dart';
import 'package:chinram_app/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _InMemoryDryerCustomerRepository implements DryerCustomerRepository {
  final Map<String, DryerCustomer> _store = {};

  @override
  Future<void> add(DryerCustomer customer) async {
    _store[customer.id] = customer;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<DryerCustomer>> getAll() async {
    final list = _store.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<DryerCustomer?> getById(String id) async => _store[id];

  @override
  Future<DryerCustomer?> getByPhoneNumber(String phoneNumber) async {
    final target = DryerCalculator.normalizePhoneNumber(phoneNumber);
    for (final customer in _store.values) {
      if (DryerCalculator.normalizePhoneNumber(customer.phoneNumber) ==
          target) {
        return customer;
      }
    }
    return null;
  }

  @override
  Future<void> update(DryerCustomer customer) async {
    _store[customer.id] = customer;
  }
}

class _InMemoryDryerVisitRepository implements DryerVisitRepository {
  final Map<String, DryerVisit> _store = {};
  final Completer<void>? addGate;

  _InMemoryDryerVisitRepository({this.addGate});

  @override
  Future<void> add(DryerVisit visit) async {
    if (addGate != null && !addGate!.isCompleted) {
      await addGate!.future;
    }
    _store[visit.id] = visit;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> deleteByCustomerId(String customerId) async {
    _store.removeWhere((_, v) => v.customerId == customerId);
  }

  @override
  Future<List<DryerVisit>> getAll() async {
    final list = _store.values.toList();
    list.sort(DryerVisit.compareNewestFirst);
    return list;
  }

  @override
  Future<List<DryerVisit>> getByCustomerId(String customerId) async {
    final list =
        _store.values.where((v) => v.customerId == customerId).toList();
    list.sort(DryerVisit.compareNewestFirst);
    return list;
  }

  @override
  Future<DryerVisit?> getById(String id) async => _store[id];

  @override
  Future<void> update(DryerVisit visit) async {
    _store[visit.id] = visit;
  }
}

void main() {
  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: '/dryer',
      routes: [
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
          ],
        ),
      ],
    );
  }

  testWidgets(
      'DryerScreen shows customer cards once per customer, sorted newest first, and supports search & filters',
      (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository();
    final service = DryerService(customerRepo, visitRepo);

    final ravi = await service.saveCustomerAndVisit(
      name: 'Ravi Shankar',
      phoneNumber: '9876543210',
      address: 'Munnar Road',
      areaType: DryerAreaType.acre,
      areaValue: 2,
      visitDate: DateTime(2026, 11, 2),
      greenQuantity: 600,
      product: DryerProduct.cardamom,
      dryQuantity: 120,
      rate: 10,
    );

    // Second visit for Ravi -> must NOT create duplicate card
    await service.saveCustomerAndVisit(
      existingCustomerId: ravi.customer.id,
      name: 'Ravi Shankar',
      phoneNumber: '9876543210',
      address: 'Munnar Road',
      areaType: DryerAreaType.acre,
      areaValue: 2,
      visitDate: DateTime(2026, 11, 10),
      greenQuantity: 500,
      product: DryerProduct.pepper,
      dryQuantity: 125,
      rate: 12,
    );

    final now = DateTime.now();
    await service.saveCustomerAndVisit(
      name: 'Anita Paul',
      phoneNumber: '9123456789',
      address: 'Thekkady',
      areaType: DryerAreaType.plants,
      areaValue: 500,
      visitDate: DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 30)),
      greenQuantity: 300,
      product: DryerProduct.coffee,
      dryQuantity: 100,
      rate: 8,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify FAB label & no duplicate cards
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Ravi Shankar'), findsOneWidget);
    expect(find.text('Anita Paul'), findsOneWidget);
    expect(find.text('2 Acres'), findsOneWidget);
    expect(find.text('500 Plants'), findsOneWidget);
    expect(find.text('₹6,000.00'), findsOneWidget);
    expect(find.text('₹2,400.00'), findsOneWidget);

    // Verify sorting: Ravi (Nov 10) appears above Anita (older)
    final raviOffset = tester.getTopLeft(find.text('Ravi Shankar')).dy;
    final anitaOffset = tester.getTopLeft(find.text('Anita Paul')).dy;
    expect(raviOffset, lessThan(anitaOffset));

    // Product filter: Coffee -> only Anita
    await tester.tap(find.widgetWithText(ChoiceChip, 'Coffee'));
    await tester.pumpAndSettle();
    expect(find.text('Anita Paul'), findsOneWidget);
    expect(find.text('Ravi Shankar'), findsNothing);

    // Clear filters -> both return
    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Ravi Shankar'), findsOneWidget);
    expect(find.text('Anita Paul'), findsOneWidget);

    // Search by phone
    await tester.enterText(find.byType(TextField).first, '98765');
    await tester.pumpAndSettle();
    expect(find.text('Ravi Shankar'), findsOneWidget);
    expect(find.text('Anita Paul'), findsNothing);

    // Clear search
    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    // Date filter: pick today -> neither matches, shows empty match + clear filters
    await tester.tap(find.text('Visit Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('No Matching Customers'), findsOneWidget);

    await tester.tap(find.text('Clear Filters').last);
    await tester.pumpAndSettle();
    expect(find.text('Ravi Shankar'), findsOneWidget);
    expect(find.text('Anita Paul'), findsOneWidget);
  });

  testWidgets(
      'DryerAddFormScreen performs real-time Percentage/Charges math, validates zero dry qty, prevents double-tap duplicate submit, and saves new customer',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final gate = Completer<void>();
    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository(addGate: gate);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    // Fill customer fields
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Customer Name *'),
      'Karthik Raja',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number *'),
      '9876501234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address *'),
      '10 Estate Line',
    );

    final areaDropdown = find.byType(DropdownButtonFormField<DryerAreaType>);
    await tester.ensureVisible(areaDropdown);
    await tester.tap(areaDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acre').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Area Value *'),
      '2',
    );

    // Fill drying fields with zero dry quantity first -> validation must reject
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Green Quantity (kg) *'),
      '600',
    );

    final productDropdown = find.byType(DropdownButtonFormField<DryerProduct>);
    await tester.ensureVisible(productDropdown);
    await tester.tap(productDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cardamom').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dry Quantity (kg) *'),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Rate (₹) *'),
      '10',
    );
    await tester.pumpAndSettle();

    // Charges updates immediately even while Dry is 0
    expect(find.text('₹6,000.00'), findsOneWidget);

    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Dry quantity must be greater than zero'), findsOneWidget);

    // Fix Dry Quantity to 120 -> Percentage updates live to 5
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dry Quantity (kg) *'),
      '120',
    );
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);

    // Double-tap Save rapidly while save is in flight -> only 1 visit created
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Customer Management'), findsOneWidget);
    expect(find.text('Karthik Raja'), findsOneWidget);
    expect(find.text('2 Acres'), findsOneWidget);
    expect(find.text('1 visit'), findsOneWidget);
    expect(find.text('₹6,000.00'), findsOneWidget);

    final visits = await visitRepo.getAll();
    expect(visits.length, 1);
  });

  testWidgets(
      'Returning customer search fills profile, visit detail/edit works, and deleting visit preserves customer and recalculates latest visit',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository();
    final service = DryerService(customerRepo, visitRepo);

    await service.saveCustomerAndVisit(
      name: 'Priya Nair',
      phoneNumber: '9888877777',
      address: '45 Spice Garden',
      areaType: DryerAreaType.plants,
      areaValue: 500,
      visitDate: DateTime(2026, 11, 1),
      greenQuantity: 400,
      product: DryerProduct.pepper,
      dryQuantity: 100,
      rate: 10,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Add Customer
    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    // Search returning customer by phone number
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number *'),
      '98888',
    );
    await tester.pumpAndSettle();

    expect(find.text('Returning Customers Found'), findsOneWidget);
    await tester.tap(find.text('Select').first);
    await tester.pumpAndSettle();

    // Verify all 5 customer fields auto-filled
    expect(find.text('Priya Nair'), findsWidgets);
    expect(find.text('9888877777'), findsOneWidget);
    expect(find.text('45 Spice Garden'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DropdownButtonFormField<DryerAreaType>),
        matching: find.text('Plants'),
      ),
      findsOneWidget,
    );
    expect(find.text('500'), findsOneWidget);

    // Fill second visit
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Green Quantity (kg) *'),
      '600',
    );
    final productDropdown = find.byType(DropdownButtonFormField<DryerProduct>);
    await tester.ensureVisible(productDropdown);
    await tester.tap(productDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cardamom').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dry Quantity (kg) *'),
      '120',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Rate (₹) *'),
      '15',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    // Back on Customer Management: still only 1 card for Priya Nair, showing latest charges ₹9,000.00
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('2 visits'), findsOneWidget);
    expect(find.text('₹9,000.00'), findsOneWidget);

    // Tap customer card -> Customer Details
    await tester.tap(find.text('Priya Nair'));
    await tester.pumpAndSettle();

    expect(find.text('Previous Visits (2)'), findsOneWidget);

    // Tap newest visit -> Visit Detail Screen -> Edit Visit
    await tester.tap(find.text('Cardamom').first);
    await tester.pumpAndSettle();
    expect(find.text('Drying Visit Details'), findsOneWidget);

    await tester.tap(find.text('Edit Visit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Drying Visit'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Rate (₹) *'),
      '20',
    );
    await tester.pumpAndSettle();
    expect(find.text('₹12,000.00'), findsOneWidget);

    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    // Back on Visit Detail: updated charges shown
    expect(find.text('₹12,000.00'), findsOneWidget);

    // Delete this visit from Visit Detail
    await tester.tap(find.text('Delete Visit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Returned to Customer Details: customer profile remains, 1 visit left
    expect(find.text('Customer Details'), findsOneWidget);
    expect(find.text('Previous Visits (1)'), findsOneWidget);

    // Edit customer profile
    await tester.tap(find.text('Edit Customer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address *'),
      '99 Updated Hills',
    );
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('99 Updated Hills'), findsOneWidget);

    // Pop back to Customer Management -> latest visit recalculated to ₹4,000.00 (Pepper)
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('₹4,000.00'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DryerCustomerCard),
        matching: find.text('Pepper'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Renders without RenderFlex overflow on narrow 320px mobile screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customerRepo = _InMemoryDryerCustomerRepository();
    final visitRepo = _InMemoryDryerVisitRepository();
    final service = DryerService(customerRepo, visitRepo);

    final saved = await service.saveCustomerAndVisit(
      name: 'Very Long Customer Name For Narrow Screen Check',
      phoneNumber: '+91 98765 43210',
      address: 'Long Estate Road, High Range District, Kerala 685501',
      areaType: DryerAreaType.acre,
      areaValue: 12.75,
      visitDate: DateTime(2026, 11, 11),
      greenQuantity: 1250.5,
      product: DryerProduct.cardamom,
      dryQuantity: 250.1,
      rate: 15.5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dryerCustomerRepositoryProvider.overrideWithValue(customerRepo),
          dryerVisitRepositoryProvider.overrideWithValue(visitRepo),
        ],
        child: MaterialApp.router(
          routerConfig: buildTestRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Open Customer Detail on narrow mobile screen
    await tester.tap(find.text('Very Long Customer Name For Narrow Screen Check'));
    await tester.pumpAndSettle();
    expect(find.text('Customer Details'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Open Add Form from Customer Detail (scroll down first on small screen)
    await tester.ensureVisible(find.text('Add Visit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Visit'));
    await tester.pumpAndSettle();
    expect(find.text('Add Drying Visit'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Verify customer was preloaded cleanly
    expect(find.text(saved.customer.phoneNumber), findsOneWidget);
  });
}
