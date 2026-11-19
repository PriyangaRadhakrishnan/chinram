import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tree_count_model.dart';
import '../models/tree_count_ledger_model.dart';
import '../repositories/tree_count_repository.dart';
import '../repositories/hive_tree_count_repository.dart';
import '../services/tree_count_service.dart';

final treeCountRepositoryProvider = Provider<TreeCountRepository>((ref) {
  return HiveTreeCountRepository();
});

final treeCountServiceProvider = Provider<TreeCountService>((ref) {
  final repository = ref.watch(treeCountRepositoryProvider);
  return TreeCountService(repository);
});

// Manage logs of tree counts
class TreeCountListNotifier extends AsyncNotifier<List<TreeCountModel>> {
  late TreeCountService _service;

  @override
  Future<List<TreeCountModel>> build() async {
    _service = ref.watch(treeCountServiceProvider);
    return _service.getTreeCounts();
  }

  Future<void> addTreeCount(TreeCountModel record, int initialCount) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveTreeCount(record, initialCount);
      ref.invalidate(treeCountTransactionsProvider);
      return _service.getTreeCounts();
    });
  }

  Future<void> updateTreeCount(TreeCountModel record, int count) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveTreeCount(record, count);
      ref.invalidate(treeCountTransactionsProvider);
      return _service.getTreeCounts();
    });
  }

  Future<void> deleteTreeCount(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteTreeCount(id);
      ref.invalidate(treeCountTransactionsProvider);
      return _service.getTreeCounts();
    });
  }
}

final treeCountListProvider = AsyncNotifierProvider<TreeCountListNotifier, List<TreeCountModel>>(() {
  return TreeCountListNotifier();
});

// Internal transaction list provider
final treeCountTransactionsProvider = FutureProvider<List<TreeCountLedgerModel>>((ref) async {
  final service = ref.watch(treeCountServiceProvider);
  return service.getLedgerTransactions();
});

// Computed provider returning map of quantities by treeCountId
final treeCountLedgerMapProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final txsAsync = ref.watch(treeCountTransactionsProvider);
  return txsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (txs) {
      final Map<String, int> map = {};
      for (final tx in txs) {
        map[tx.treeCountId] = (map[tx.treeCountId] ?? 0) + tx.quantity;
      }
      return AsyncValue.data(map);
    },
  );
});
