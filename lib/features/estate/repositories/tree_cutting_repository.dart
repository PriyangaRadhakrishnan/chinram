import '../models/tree_cutting_model.dart';

abstract class TreeCuttingRepository {
  Future<List<TreeCuttingModel>> getTreeCuttings();
  Future<TreeCuttingModel?> getTreeCuttingById(String id);
  Future<void> saveTreeCutting(TreeCuttingModel record);
  Future<void> deleteTreeCutting(String id);
}
