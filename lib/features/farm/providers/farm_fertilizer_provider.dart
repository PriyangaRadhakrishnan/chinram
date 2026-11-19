import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_fertilizer_model.dart';
import '../models/farm_organic_fertilizer_model.dart';
import '../models/farm_fertilizer_usage_model.dart';
import '../repositories/farm_fertilizer_repository.dart';
import '../repositories/hive_farm_fertilizer_repository.dart';
import '../services/farm_fertilizer_service.dart';

final farmChemicalInventoryRepositoryProvider = Provider<FarmChemicalInventoryRepository>((ref) {
  return HiveFarmChemicalInventoryRepository();
});

final farmChemicalUsageRepositoryProvider = Provider<FarmChemicalUsageRepository>((ref) {
  return HiveFarmChemicalUsageRepository();
});

final farmOrganicInventoryRepositoryProvider = Provider<FarmOrganicInventoryRepository>((ref) {
  return HiveFarmOrganicInventoryRepository();
});

final farmFertilizerServiceProvider = Provider<FarmFertilizerService>((ref) {
  return FarmFertilizerService(
    chemicalInventory: ref.watch(farmChemicalInventoryRepositoryProvider),
    chemicalUsages: ref.watch(farmChemicalUsageRepositoryProvider),
    organicInventory: ref.watch(farmOrganicInventoryRepositoryProvider),
  );
});

// Chemical Inventory Notifier
class FarmChemicalInventoryNotifier extends AsyncNotifier<List<FarmFertilizerModel>> {
  late final FarmFertilizerService _service;

  @override
  Future<List<FarmFertilizerModel>> build() async {
    _service = ref.watch(farmFertilizerServiceProvider);
    return _service.getChemicalInventory();
  }

  Future<void> addChemical(FarmFertilizerModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.addChemical(record);
      return _service.getChemicalInventory();
    });
  }

  Future<void> updateChemical(FarmFertilizerModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateChemical(record);
      return _service.getChemicalInventory();
    });
  }

  Future<void> deleteChemical(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteChemical(id);
      return _service.getChemicalInventory();
    });
  }
}

final farmChemicalInventoryProvider = AsyncNotifierProvider<FarmChemicalInventoryNotifier, List<FarmFertilizerModel>>(() {
  return FarmChemicalInventoryNotifier();
});

// Chemical Usages Notifier
class FarmChemicalUsagesNotifier extends AsyncNotifier<List<FarmFertilizerUsageModel>> {
  late final FarmFertilizerService _service;

  @override
  Future<List<FarmFertilizerUsageModel>> build() async {
    _service = ref.watch(farmFertilizerServiceProvider);
    return _service.getChemicalUsages();
  }

  Future<void> addUsage(FarmFertilizerUsageModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.addChemicalUsage(record);
      return _service.getChemicalUsages();
    });
  }

  Future<void> updateUsage(FarmFertilizerUsageModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateChemicalUsage(record);
      return _service.getChemicalUsages();
    });
  }

  Future<void> deleteUsage(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteChemicalUsage(id);
      return _service.getChemicalUsages();
    });
  }
}

final farmChemicalUsagesProvider = AsyncNotifierProvider<FarmChemicalUsagesNotifier, List<FarmFertilizerUsageModel>>(() {
  return FarmChemicalUsagesNotifier();
});

// Organic Inventory Notifier
class FarmOrganicInventoryNotifier extends AsyncNotifier<List<FarmOrganicFertilizerModel>> {
  late final FarmFertilizerService _service;

  @override
  Future<List<FarmOrganicFertilizerModel>> build() async {
    _service = ref.watch(farmFertilizerServiceProvider);
    return _service.getOrganicInventory();
  }

  Future<void> addOrganic(FarmOrganicFertilizerModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.addOrganic(record);
      return _service.getOrganicInventory();
    });
  }

  Future<void> updateOrganic(FarmOrganicFertilizerModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateOrganic(record);
      return _service.getOrganicInventory();
    });
  }

  Future<void> deleteOrganic(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteOrganic(id);
      return _service.getOrganicInventory();
    });
  }
}

final farmOrganicInventoryProvider = AsyncNotifierProvider<FarmOrganicInventoryNotifier, List<FarmOrganicFertilizerModel>>(() {
  return FarmOrganicInventoryNotifier();
});

// Calculation: Chemical stock mapping
final farmChemicalStockMapProvider = Provider<Map<String, double>>((ref) {
  final inventory = ref.watch(farmChemicalInventoryProvider).value ?? [];
  final usages = ref.watch(farmChemicalUsagesProvider).value ?? [];

  final Map<String, double> map = {};
  for (final item in inventory) {
    map[item.id] = item.initialStock;
  }
  for (final usage in usages) {
    if (map.containsKey(usage.fertilizerId)) {
      map[usage.fertilizerId] = map[usage.fertilizerId]! - usage.bagsUsed;
    }
  }
  return map;
});
