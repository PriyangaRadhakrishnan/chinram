import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tree_cutting_model.dart';
import '../repositories/tree_cutting_repository.dart';
import '../repositories/hive_tree_cutting_repository.dart';
import '../services/tree_cutting_service.dart';

final treeCuttingRepositoryProvider = Provider<TreeCuttingRepository>((ref) {
  return HiveTreeCuttingRepository();
});

final treeCuttingServiceProvider = Provider<TreeCuttingService>((ref) {
  final cuttingRepo = ref.watch(treeCuttingRepositoryProvider);
  return TreeCuttingService(cuttingRepo);
});

// Manage logs of tree cutting
class TreeCuttingListNotifier extends AsyncNotifier<List<TreeCuttingModel>> {
  late TreeCuttingService _service;

  @override
  Future<List<TreeCuttingModel>> build() async {
    _service = ref.watch(treeCuttingServiceProvider);
    return _service.getTreeCuttings();
  }

  Future<void> addTreeCutting(TreeCuttingModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveTreeCutting(record);
      return _service.getTreeCuttings();
    });
  }

  Future<void> updateTreeCutting(TreeCuttingModel record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.saveTreeCutting(record);
      return _service.getTreeCuttings();
    });
  }

  Future<void> deleteTreeCutting(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteTreeCutting(id);
      return _service.getTreeCuttings();
    });
  }
}

final treeCuttingListProvider = AsyncNotifierProvider<TreeCuttingListNotifier, List<TreeCuttingModel>>(() {
  return TreeCuttingListNotifier();
});
