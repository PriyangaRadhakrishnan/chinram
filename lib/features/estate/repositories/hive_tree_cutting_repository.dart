import 'package:hive/hive.dart';
import '../models/tree_cutting_model.dart';
import 'tree_cutting_repository.dart';

class HiveTreeCuttingRepository implements TreeCuttingRepository {
  static const String _boxName = 'tree_cuttings_box';

  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  @override
  Future<List<TreeCuttingModel>> getTreeCuttings() async {
    final box = await _getBox();
    final List<TreeCuttingModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(TreeCuttingModel.fromJson(value));
      }
    }
    // Sort chronologically by date descending
    list.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.createdTime.compareTo(a.createdTime);
    });
    return list;
  }

  @override
  Future<TreeCuttingModel?> getTreeCuttingById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return TreeCuttingModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> saveTreeCutting(TreeCuttingModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> deleteTreeCutting(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
