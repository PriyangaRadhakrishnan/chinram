import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinram_app/features/estate/models/worker_model.dart';
import 'package:chinram_app/features/estate/repositories/mock_worker_repository.dart';
import 'package:chinram_app/features/estate/providers/worker_provider.dart';
import 'package:chinram_app/features/estate/screens/worker_list_screen.dart';
import 'package:chinram_app/features/estate/screens/worker_form_screen.dart';
import 'package:chinram_app/features/estate/screens/worker_detail_screen.dart';
import 'package:chinram_app/shared/widgets/search_bar_widget.dart';
import 'package:chinram_app/shared/widgets/primary_button.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:chinram_app/features/estate/repositories/hive_worker_repository.dart';

void main() {
  setUp(() {
    MockWorkerRepository.reset();
  });

  group('Worker Model & Mock Repository Unit Tests', () {
    test('MockWorkerRepository initializes with default list', () async {
      final repo = MockWorkerRepository();
      final workers = await repo.getAll();
      expect(workers.length, 5);
      expect(workers[0].name, 'Ramesh Kumar');
      expect(workers[1].name, 'Priyanga Radhakrishnan');
    });

    test('MockWorkerRepository adds a new worker', () async {
      final repo = MockWorkerRepository();
      final before = await repo.getAll();
      final originalLength = before.length;
      const newWorker = WorkerModel(
        id: '10',
        name: 'New Tester',
        gender: WorkerGender.female,
        phoneNumber: '1234567890',
        status: WorkerStatus.active,
      );
      await repo.add(newWorker);
      final workers = await repo.getAll();
      expect(workers.length, originalLength + 1);
      expect(workers.last.name, 'New Tester');
    });

    test('MockWorkerRepository updates an existing worker', () async {
      final repo = MockWorkerRepository();
      final workersBefore = await repo.getAll();
      final first = workersBefore.first;
      final updated = first.copyWith(name: 'Ramesh Kumar Updated', status: WorkerStatus.inactive);
      await repo.update(updated);

      final firstAfter = await repo.getById(first.id);
      expect(firstAfter?.name, 'Ramesh Kumar Updated');
      expect(firstAfter?.status, WorkerStatus.inactive);
    });

    test('MockWorkerRepository deletes a worker', () async {
      final repo = MockWorkerRepository();
      final before = await repo.getAll();
      final originalLength = before.length;
      await repo.delete('1');
      final workers = await repo.getAll();
      expect(workers.length, originalLength - 1);
      expect(workers.any((w) => w.id == '1'), false);
    });
  });

  group('Worker Riverpod Provider State Tests', () {
    test('WorkerListNotifier adds, updates, and deletes correctly', () async {
      final container = ProviderContainer(
        overrides: [
          workerRepositoryProvider.overrideWithValue(MockWorkerRepository()),
        ],
      );

      // Listen to provider
      final subscription = container.listen(
        workerListProvider,
        (previous, next) {},
        fireImmediately: true,
      );

      // Initial state is loading, wait for data
      await container.read(workerListProvider.future);
      expect(container.read(workerListProvider).value?.length, 5);

      // Test Add
      const w = WorkerModel(
        id: '101',
        name: 'Riverpod Worker',
        gender: WorkerGender.male,
        phoneNumber: '0987654321',
        status: WorkerStatus.active,
      );
      await container.read(workerListProvider.notifier).addWorker(w);
      expect(container.read(workerListProvider).value?.length, 6);
      expect(container.read(workerListProvider).value?.any((item) => item.id == '101'), true);

      // Test Update
      final updated = w.copyWith(name: 'Riverpod Worker Updated');
      await container.read(workerListProvider.notifier).updateWorker(updated);
      final found = container.read(workerListProvider).value?.firstWhere((item) => item.id == '101');
      expect(found?.name, 'Riverpod Worker Updated');

      // Test Delete
      await container.read(workerListProvider.notifier).deleteWorker('101');
      expect(container.read(workerListProvider).value?.length, 5);
      expect(container.read(workerListProvider).value?.any((item) => item.id == '101'), false);

      subscription.close();
    });
   group('Worker Management Widget Tests', () {
    testWidgets('WorkerListScreen renders correctly and shows search/filters', (tester) async {
      // Set larger screen to mock desktop size or normal size
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerRepositoryProvider.overrideWithValue(MockWorkerRepository()),
          ],
          child: const MaterialApp(
            home: WorkerListScreen(),
          ),
        ),
      );

      // Wait for mock delay
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify page shows search bar and list items
      expect(find.byType(SearchBarWidget), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsWidgets);
      expect(find.text('Priyanga Radhakrishnan'), findsWidgets);

      // Test Search box
      await tester.enterText(find.byType(TextField), 'Priyanga');
      await tester.pumpAndSettle();

      // Only Priyanga should show up
      expect(find.text('Ramesh Kumar'), findsNothing);
      expect(find.text('Priyanga Radhakrishnan'), findsWidgets);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Ramesh Kumar'), findsWidgets);
    });

    testWidgets('WorkerFormScreen validates mandatory fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerRepositoryProvider.overrideWithValue(MockWorkerRepository()),
          ],
          child: const MaterialApp(
            home: WorkerFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try saving without selecting gender
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Expect validation error for gender
      expect(find.text('Please select gender'), findsOneWidget);
    });

    testWidgets('WorkerDetailScreen renders profile correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerListProvider.overrideWith(() => MockNotifier([
              const WorkerModel(
                id: '2',
                name: 'Priyanga Radhakrishnan',
                gender: WorkerGender.female,
                phoneNumber: '9876543211',
                status: WorkerStatus.active,
                notes: 'Dryer supervisor.',
              )
            ])),
          ],
          child: const MaterialApp(
            home: WorkerDetailScreen(workerId: '2'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify labels and content
      expect(find.text('Worker Profile'), findsOneWidget);
      expect(find.text('Priyanga Radhakrishnan'), findsOneWidget);
      expect(find.text('Female'), findsWidgets);
      expect(find.text('9876543211'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Dryer supervisor.'), findsOneWidget);
    });

    testWidgets('WorkerDetailScreen renders "-" for empty optional fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerListProvider.overrideWith(() => MockNotifier([
              const WorkerModel(
                id: '3',
                name: null,
                gender: WorkerGender.male,
                phoneNumber: null,
                status: WorkerStatus.active,
                notes: null,
              )
            ])),
          ],
          child: const MaterialApp(
            home: WorkerDetailScreen(workerId: '3'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render "-" for name, phone, and notes
      expect(find.text('-'), findsWidgets);
    });
  });
  });

  group('HiveWorkerRepository Unit Tests', () {
    late Directory tempDir;
    late HiveWorkerRepository hiveRepo;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_tests');
      Hive.init(tempDir.path);
    });

    setUp(() async {
      hiveRepo = HiveWorkerRepository();
    });

    tearDownAll(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('starts with an empty list', () async {
      final list = await hiveRepo.getAll();
      expect(list, isEmpty);
    });

    test('adds, retrieves, updates, and deletes workers in Hive', () async {
      const worker = WorkerModel(
        id: 'hive-1',
        name: 'Hive Tapper',
        gender: WorkerGender.male,
        phoneNumber: '1234567890',
        status: WorkerStatus.active,
        notes: 'Some notes',
      );

      // Add
      await hiveRepo.add(worker);
      var list = await hiveRepo.getAll();
      expect(list.length, 1);
      expect(list.first.name, 'Hive Tapper');

      // Get by id
      final retrieved = await hiveRepo.getById('hive-1');
      expect(retrieved?.name, 'Hive Tapper');

      // Update
      final updated = worker.copyWith(name: 'Hive Tapper Updated');
      await hiveRepo.update(updated);
      final retrievedUpdated = await hiveRepo.getById('hive-1');
      expect(retrievedUpdated?.name, 'Hive Tapper Updated');

      // Delete
      await hiveRepo.delete('hive-1');
      list = await hiveRepo.getAll();
      expect(list, isEmpty);
    });
  });
}

class MockNotifier extends WorkerListNotifier {
  final List<WorkerModel> _initial;
  MockNotifier(this._initial);

  @override
  Future<List<WorkerModel>> build() async {
    return _initial;
  }
}
