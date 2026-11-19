import '../models/tree_cutting_model.dart';
import '../repositories/tree_cutting_repository.dart';

class TreeCuttingService {
  final TreeCuttingRepository _cuttingRepository;

  const TreeCuttingService(this._cuttingRepository);

  Future<List<TreeCuttingModel>> getTreeCuttings() => _cuttingRepository.getTreeCuttings();
  Future<TreeCuttingModel?> getTreeCuttingById(String id) => _cuttingRepository.getTreeCuttingById(id);

  Future<void> saveTreeCutting(TreeCuttingModel record) async {
    await _cuttingRepository.saveTreeCutting(record);
  }

  Future<void> deleteTreeCutting(String id) async {
    await _cuttingRepository.deleteTreeCutting(id);
  }
}
