import 'package:hive/hive.dart';
import '../models/organic_fertilizer_model.dart';
import 'organic_fertilizer_repository.dart';

class HiveOrganicFertilizerRepository implements OrganicFertilizerRepository {
  static const String _boxName = 'organic_fertilizers_box';

  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  @override
  Future<List<OrganicFertilizerModel>> getAll() async {
    final box = await _getBox();
    final List<OrganicFertilizerModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(OrganicFertilizerModel.fromJson(value));
      }
    }
    // Sort by date descending
    list.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      final createdDateCompare = b.createdDate.compareTo(a.createdDate);
      if (createdDateCompare != 0) return createdDateCompare;
      return b.createdTime.compareTo(a.createdTime);
    });
    return list;
  }

  @override
  Future<OrganicFertilizerModel?> getById(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is Map) {
      return OrganicFertilizerModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> save(OrganicFertilizerModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
