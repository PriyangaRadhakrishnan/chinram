import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/fertilizer_transaction_model.dart';
import '../repositories/fertilizer_repository.dart';
import '../repositories/hive_fertilizer_repository.dart';
import '../services/fertilizer_service.dart';

final fertilizerRepositoryProvider = Provider<FertilizerRepository>((ref) {
  return HiveFertilizerRepository();
});

final fertilizerServiceProvider = Provider<FertilizerService>((ref) {
  final repository = ref.watch(fertilizerRepositoryProvider);
  return FertilizerService(repository);
});

// Manage logs of inventory purchases
class FertilizerInventoryNotifier extends AsyncNotifier<List<FertilizerModel>> {
  late FertilizerService _service;

  @override
  Future<List<FertilizerModel>> build() async {
    _service = ref.watch(fertilizerServiceProvider);
    return _service.getFertilizers();
  }

  Future<void> addFertilizer(FertilizerModel fertilizer, int initialStock) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveFertilizer(fertilizer, initialStock);
      // Invalidate the transactions state and reload lists
      ref.invalidate(fertilizerTransactionsProvider);
      return _service.getFertilizers();
    });
  }

  Future<void> updateFertilizer(FertilizerModel fertilizer, int stock) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveFertilizer(fertilizer, stock);
      ref.invalidate(fertilizerTransactionsProvider);
      return _service.getFertilizers();
    });
  }

  Future<void> deleteFertilizer(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteFertilizer(id);
      ref.invalidate(fertilizerTransactionsProvider);
      ref.invalidate(fertilizerUsagesProvider);
      return _service.getFertilizers();
    });
  }
}

final fertilizerInventoryProvider = AsyncNotifierProvider<FertilizerInventoryNotifier, List<FertilizerModel>>(() {
  return FertilizerInventoryNotifier();
});

// Manage logs of stock usages
class FertilizerUsagesNotifier extends AsyncNotifier<List<FertilizerUsageModel>> {
  late FertilizerService _service;

  @override
  Future<List<FertilizerUsageModel>> build() async {
    _service = ref.watch(fertilizerServiceProvider);
    return _service.getUsages();
  }

  Future<void> addUsage(FertilizerUsageModel usage) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveUsage(usage);
      ref.invalidate(fertilizerTransactionsProvider);
      ref.invalidate(fertilizerInventoryProvider);
      return _service.getUsages();
    });
  }

  Future<void> updateUsage(FertilizerUsageModel usage) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveUsage(usage);
      ref.invalidate(fertilizerTransactionsProvider);
      ref.invalidate(fertilizerInventoryProvider);
      return _service.getUsages();
    });
  }

  Future<void> deleteUsage(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteUsage(id);
      ref.invalidate(fertilizerTransactionsProvider);
      ref.invalidate(fertilizerInventoryProvider);
      return _service.getUsages();
    });
  }
}

final fertilizerUsagesProvider = AsyncNotifierProvider<FertilizerUsagesNotifier, List<FertilizerUsageModel>>(() {
  return FertilizerUsagesNotifier();
});

// Internal transaction list provider
final fertilizerTransactionsProvider = FutureProvider<List<FertilizerTransactionModel>>((ref) async {
  final service = ref.watch(fertilizerServiceProvider);
  return service.getTransactions();
});

// Computed provider returning map of stock values by fertilizerId
final fertilizerStockMapProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final txsAsync = ref.watch(fertilizerTransactionsProvider);
  return txsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (txs) {
      final Map<String, double> map = {};
      for (final tx in txs) {
        map[tx.fertilizerId] = (map[tx.fertilizerId] ?? 0.0) + tx.quantity;
      }
      return AsyncValue.data(map);
    },
  );
});
