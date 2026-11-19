import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organic_fertilizer_model.dart';
import '../repositories/organic_fertilizer_repository.dart';
import '../repositories/hive_organic_fertilizer_repository.dart';
import '../services/organic_fertilizer_service.dart';

final organicFertilizerRepositoryProvider = Provider<OrganicFertilizerRepository>((ref) {
  return HiveOrganicFertilizerRepository();
});

final organicFertilizerServiceProvider = Provider<OrganicFertilizerService>((ref) {
  final repository = ref.watch(organicFertilizerRepositoryProvider);
  return OrganicFertilizerService(repository);
});

class OrganicFertilizerListNotifier extends AsyncNotifier<List<OrganicFertilizerModel>> {
  late final OrganicFertilizerService _service;

  @override
  Future<List<OrganicFertilizerModel>> build() async {
    _service = ref.watch(organicFertilizerServiceProvider);
    return _service.getAll();
  }

  Future<void> addOrganicFertilizer(OrganicFertilizerModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(record);
      return _service.getAll();
    });
  }

  Future<void> updateOrganicFertilizer(OrganicFertilizerModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.save(record);
      return _service.getAll();
    });
  }

  Future<void> deleteOrganicFertilizer(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.delete(id);
      return _service.getAll();
    });
  }
}

final organicFertilizerListProvider = AsyncNotifierProvider<OrganicFertilizerListNotifier, List<OrganicFertilizerModel>>(() {
  return OrganicFertilizerListNotifier();
});
