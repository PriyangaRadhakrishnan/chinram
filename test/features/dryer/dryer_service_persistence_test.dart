import 'dart:io';

import 'package:chinram_app/features/dryer/models/dryer_customer_model.dart';
import 'package:chinram_app/features/dryer/models/dryer_visit_model.dart';
import 'package:chinram_app/features/dryer/providers/dryer_provider.dart';
import 'package:chinram_app/features/dryer/repositories/hive_dryer_customer_repository.dart';
import 'package:chinram_app/features/dryer/repositories/hive_dryer_visit_repository.dart';
import 'package:chinram_app/features/dryer/services/dryer_service.dart';
import 'package:chinram_app/features/dryer/utils/dryer_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('DryerCalculator Unit Tests', () {
    test('calculates exact percentage as Green / Dry without *100', () {
      expect(DryerCalculator.calculatePercentage(600, 120), 5.0);
      expect(DryerCalculator.formatPercentage(5.0), '5');

      expect(DryerCalculator.calculatePercentage(600, 125), 4.8);
      expect(DryerCalculator.formatPercentage(4.8), '4.8');

      expect(DryerCalculator.calculatePercentage(380, 61.5), 6.18);
      expect(DryerCalculator.formatPercentage(6.18), '6.18');
    });

    test('avoids floating-point display artifacts in percentage and charges',
        () {
      expect(DryerCalculator.calculatePercentage(0.3, 0.1), 3.0);
      expect(DryerCalculator.formatPercentage(3.0), '3');

      expect(DryerCalculator.calculateCharges(0.1, 0.2), 0.02);
      expect(DryerCalculator.calculateCharges(19.99, 3), 59.97);
    });

    test('calculates charges as Green * Rate including decimals and zero rate',
        () {
      expect(DryerCalculator.calculateCharges(600, 10), 6000.0);
      expect(DryerCalculator.calculateCharges(125.5, 12.5), 1568.75);
      expect(DryerCalculator.calculateCharges(600, 0), 0.0);
    });

    test('rejects zero dry quantity, non-positive green, negative rate, NaN, and Infinity',
        () {
      expect(
        () => DryerCalculator.calculatePercentage(600, 0),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculatePercentage(0, 120),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculatePercentage(-10, 10),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculatePercentage(double.nan, 10),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculatePercentage(100, double.infinity),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculateCharges(600, -1),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculateCharges(0, 10),
        throwsArgumentError,
      );
      expect(
        () => DryerCalculator.calculateCharges(10, double.nan),
        throwsArgumentError,
      );

      expect(DryerCalculator.tryCalculatePercentage('600', '0'), isNull);
      expect(DryerCalculator.tryCalculatePercentage('NaN', '10'), isNull);
      expect(DryerCalculator.tryCalculateCharges('600', '-5'), isNull);
      expect(DryerCalculator.tryCalculateCharges('600', '0'), 0.0);
    });

    test('formats area and validates phone numbers', () {
      expect(DryerCalculator.formatArea(DryerAreaType.acre, 2), '2 Acres');
      expect(DryerCalculator.formatArea(DryerAreaType.acre, 2.5), '2.5 Acres');
      expect(
        DryerCalculator.formatArea(DryerAreaType.plants, 500),
        '500 Plants',
      );

      expect(DryerCalculator.validatePhoneNumber('9876543210'), isNull);
      expect(DryerCalculator.validatePhoneNumber('+91 98765 43210'), isNull);
      expect(DryerCalculator.validatePhoneNumber('12345'), isNotNull);
      expect(DryerCalculator.validatePhoneNumber('abc9876543'), isNotNull);
      expect(DryerCalculator.validatePhoneNumber(''), isNotNull);

      expect(
        DryerCalculator.normalizePhoneNumber('+91 98765 43210'),
        '9876543210',
      );
    });
  });

  group('DryerService & Hive Persistence Integration Tests', () {
    late Directory tempDir;
    late HiveDryerCustomerRepository customerRepo;
    late HiveDryerVisitRepository visitRepo;
    late DryerService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dryer_service_test_');
      Hive.init(tempDir.path);
      customerRepo = HiveDryerCustomerRepository();
      visitRepo = HiveDryerVisitRepository();
      service = DryerService(customerRepo, visitRepo);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates new customer and visit with decimal values', () async {
      final result = await service.saveCustomerAndVisit(
        name: 'Arun Kumar',
        phoneNumber: '9876543210',
        address: '14 Hill View, Idukki',
        areaType: DryerAreaType.acre,
        areaValue: 2.5,
        visitDate: DateTime(2026, 11, 10),
        greenQuantity: 600.5,
        product: DryerProduct.cardamom,
        dryQuantity: 120.1,
        rate: 10.5,
      );

      expect(result.isNewCustomer, isTrue);
      expect(result.customer.id, isNotEmpty);
      expect(result.visit.customerId, result.customer.id);
      expect(result.visit.percentage, 5.0);
      expect(result.visit.charges, 6305.25);

      final summaries = await service.getCustomerSummaries();
      expect(summaries.length, 1);
      expect(summaries.first.customer.name, 'Arun Kumar');
      expect(summaries.first.customer.areaValue, 2.5);
      expect(summaries.first.latestVisit?.id, result.visit.id);
    });

    test('identifies returning customer by phone and prevents duplicate profiles',
        () async {
      final firstSave = await service.saveCustomerAndVisit(
        name: 'Meena Devi',
        phoneNumber: '9876543210',
        address: '22 Valley Road',
        areaType: DryerAreaType.plants,
        areaValue: 500,
        visitDate: DateTime(2026, 11, 1),
        greenQuantity: 600,
        product: DryerProduct.cardamom,
        dryQuantity: 120,
        rate: 10,
      );

      // Returning customer identified by normalized phone even without passing existingCustomerId
      final secondSave = await service.saveCustomerAndVisit(
        name: 'Meena Devi',
        phoneNumber: '+91 98765 43210',
        address: '22 Valley Road',
        areaType: DryerAreaType.plants,
        areaValue: 500,
        visitDate: DateTime(2026, 11, 8),
        greenQuantity: 450,
        product: DryerProduct.pepper,
        dryQuantity: 150,
        rate: 8,
      );

      expect(secondSave.isNewCustomer, isFalse);
      expect(secondSave.customer.id, firstSave.customer.id);

      final allCustomers = await customerRepo.getAll();
      expect(allCustomers.length, 1);

      final allVisits = await visitRepo.getByCustomerId(firstSave.customer.id);
      expect(allVisits.length, 2);
      // Newest first
      expect(allVisits[0].id, secondSave.visit.id);
      expect(allVisits[0].product, DryerProduct.pepper);
      expect(allVisits[1].id, firstSave.visit.id);
      expect(allVisits[1].product, DryerProduct.cardamom);

      // Summary appears only once with latest visit
      final summaries = await service.getCustomerSummaries();
      expect(summaries.length, 1);
      expect(summaries.first.visitCount, 2);
      expect(summaries.first.latestVisit?.id, secondSave.visit.id);
    });

    test('editing customer profile preserves all historical visits unchanged',
        () async {
      final save1 = await service.saveCustomerAndVisit(
        name: 'Joseph Mathew',
        phoneNumber: '9123456789',
        address: 'Old Address',
        areaType: DryerAreaType.acre,
        areaValue: 2,
        visitDate: DateTime(2026, 11, 2),
        greenQuantity: 300,
        product: DryerProduct.coffee,
        dryQuantity: 100,
        rate: 12,
      );

      final save2 = await service.saveCustomerAndVisit(
        existingCustomerId: save1.customer.id,
        name: 'Joseph Mathew Jr',
        phoneNumber: '9123456789',
        address: 'New Address, Estate Gate',
        areaType: DryerAreaType.acre,
        areaValue: 3.5,
        visitDate: DateTime(2026, 11, 9),
        greenQuantity: 500,
        product: DryerProduct.cardamom,
        dryQuantity: 100,
        rate: 15,
      );

      expect(save2.customer.id, save1.customer.id);
      final visits = await service.getVisitsForCustomer(save1.customer.id);
      expect(visits.length, 2);

      // Historical first visit remained completely unchanged
      final oldVisit = visits.firstWhere((v) => v.id == save1.visit.id);
      expect(oldVisit.greenQuantity, 300);
      expect(oldVisit.dryQuantity, 100);
      expect(oldVisit.product, DryerProduct.coffee);
      expect(oldVisit.charges, 3600);
    });

    test('editing one visit updates only that visit without affecting others',
        () async {
      final first = await service.saveCustomerAndVisit(
        name: 'Suresh',
        phoneNumber: '9988776655',
        address: 'Kattappana',
        areaType: DryerAreaType.acre,
        areaValue: 4,
        visitDate: DateTime(2026, 11, 1),
        greenQuantity: 600,
        product: DryerProduct.cardamom,
        dryQuantity: 120,
        rate: 10,
      );

      final second = await service.saveCustomerAndVisit(
        existingCustomerId: first.customer.id,
        name: 'Suresh',
        phoneNumber: '9988776655',
        address: 'Kattappana',
        areaType: DryerAreaType.acre,
        areaValue: 4,
        visitDate: DateTime(2026, 11, 5),
        greenQuantity: 400,
        product: DryerProduct.pepper,
        dryQuantity: 100,
        rate: 12,
      );

      final updatedSecond = await service.updateVisit(
        existingVisit: second.visit,
        date: DateTime(2026, 11, 6),
        greenQuantity: 500,
        product: DryerProduct.coffee,
        dryQuantity: 125,
        rate: 14,
      );

      expect(updatedSecond.percentage, 4.0);
      expect(updatedSecond.charges, 7000.0);

      final visits = await service.getVisitsForCustomer(first.customer.id);
      expect(visits.length, 2);
      final unchangedFirst = visits.firstWhere((v) => v.id == first.visit.id);
      expect(unchangedFirst.greenQuantity, 600);
      expect(unchangedFirst.dryQuantity, 120);
      expect(unchangedFirst.percentage, 5.0);
      expect(unchangedFirst.charges, 6000.0);
    });

    test(
        'deleting latest visit recalculates latest visit and keeps customer when zero visits remain',
        () async {
      final visit1 = await service.saveCustomerAndVisit(
        name: 'Lakshmi',
        phoneNumber: '9001122334',
        address: 'Kumily',
        areaType: DryerAreaType.plants,
        areaValue: 400,
        visitDate: DateTime(2026, 11, 1),
        greenQuantity: 300,
        product: DryerProduct.pepper,
        dryQuantity: 100,
        rate: 10,
      );

      final visit2 = await service.saveCustomerAndVisit(
        existingCustomerId: visit1.customer.id,
        name: 'Lakshmi',
        phoneNumber: '9001122334',
        address: 'Kumily',
        areaType: DryerAreaType.plants,
        areaValue: 400,
        visitDate: DateTime(2026, 11, 10),
        greenQuantity: 600,
        product: DryerProduct.cardamom,
        dryQuantity: 120,
        rate: 15,
      );

      var summary = await service.getCustomerSummaryById(visit1.customer.id);
      expect(summary?.latestVisit?.id, visit2.visit.id);

      // Delete latest visit -> latest should recalculate to visit1
      await service.deleteVisit(visit2.visit.id);
      summary = await service.getCustomerSummaryById(visit1.customer.id);
      expect(summary, isNotNull);
      expect(summary!.visitCount, 1);
      expect(summary.latestVisit?.id, visit1.visit.id);
      expect(summary.latestVisit?.product, DryerProduct.pepper);

      // Delete remaining visit -> customer profile must still remain
      await service.deleteVisit(visit1.visit.id);
      summary = await service.getCustomerSummaryById(visit1.customer.id);
      expect(summary, isNotNull);
      expect(summary!.customer.name, 'Lakshmi');
      expect(summary.visitCount, 0);
      expect(summary.latestVisit, isNull);
    });

    test('sorts customers by latest visit date descending', () async {
      await service.saveCustomerAndVisit(
        name: 'Older Visitor',
        phoneNumber: '9111111111',
        address: 'Addr 1',
        areaType: DryerAreaType.acre,
        areaValue: 1,
        visitDate: DateTime(2026, 11, 1),
        greenQuantity: 100,
        product: DryerProduct.coffee,
        dryQuantity: 50,
        rate: 10,
      );

      await service.saveCustomerAndVisit(
        name: 'Newest Visitor',
        phoneNumber: '9222222222',
        address: 'Addr 2',
        areaType: DryerAreaType.acre,
        areaValue: 2,
        visitDate: DateTime(2026, 11, 11),
        greenQuantity: 600,
        product: DryerProduct.cardamom,
        dryQuantity: 120,
        rate: 10,
      );

      final summaries = await service.getCustomerSummaries();
      expect(summaries.length, 2);
      expect(summaries[0].customer.name, 'Newest Visitor');
      expect(summaries[1].customer.name, 'Older Visitor');
    });

    test('persists customers and visits across app restart (Hive close + reopen)',
        () async {
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      await container1.read(dryerCustomersProvider.future);
      final saved = await container1
          .read(dryerCustomersProvider.notifier)
          .saveCustomerAndVisit(
            name: 'Persistent Customer',
            phoneNumber: '9445566778',
            address: 'Estate Road 9',
            areaType: DryerAreaType.acre,
            areaValue: 3,
            visitDate: DateTime(2026, 11, 11),
            greenQuantity: 600,
            product: DryerProduct.cardamom,
            dryQuantity: 120,
            rate: 10,
          );

      // Simulate closing and reopening the app
      await Hive.close();
      Hive.init(tempDir.path);

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final loadedSummaries =
          await container2.read(dryerCustomersProvider.future);
      expect(loadedSummaries.length, 1);
      expect(loadedSummaries.first.customer.id, saved.customer.id);
      expect(loadedSummaries.first.customer.name, 'Persistent Customer');
      expect(loadedSummaries.first.customer.areaValue, 3);
      expect(loadedSummaries.first.visitCount, 1);
      expect(loadedSummaries.first.latestVisit?.id, saved.visit.id);
      expect(loadedSummaries.first.latestVisit?.percentage, 5.0);
      expect(loadedSummaries.first.latestVisit?.charges, 6000.0);
    });
  });
}
