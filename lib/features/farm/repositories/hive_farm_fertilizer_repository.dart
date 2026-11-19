import 'package:hive/hive.dart';
import '../models/farm_fertilizer_model.dart';
import '../models/farm_organic_fertilizer_model.dart';
import '../models/farm_fertilizer_usage_model.dart';
import 'farm_fertilizer_repository.dart';

class HiveFarmChemicalInventoryRepository implements FarmChemicalInventoryRepository {
  static const String _boxName = 'farm_fertilizers_box';
  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  @override
  Future<List<FarmFertilizerModel>> getAll() async {
    final box = await _getBox();
    final List<FarmFertilizerModel> list = [];
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map) list.add(FarmFertilizerModel.fromJson(val));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<FarmFertilizerModel?> getById(String id) async {
    final box = await _getBox();
    final val = box.get(id);
    if (val is Map) return FarmFertilizerModel.fromJson(val);
    return null;
  }

  @override
  Future<void> add(FarmFertilizerModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> update(FarmFertilizerModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}

class HiveFarmChemicalUsageRepository implements FarmChemicalUsageRepository {
  static const String _boxName = 'farm_fertilizer_usages_box';
  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  @override
  Future<List<FarmFertilizerUsageModel>> getAll() async {
    final box = await _getBox();
    final List<FarmFertilizerUsageModel> list = [];
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map) list.add(FarmFertilizerUsageModel.fromJson(val));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<FarmFertilizerUsageModel?> getById(String id) async {
    final box = await _getBox();
    final val = box.get(id);
    if (val is Map) return FarmFertilizerUsageModel.fromJson(val);
    return null;
  }

  @override
  Future<void> add(FarmFertilizerUsageModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> update(FarmFertilizerUsageModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}

class HiveFarmOrganicInventoryRepository implements FarmOrganicInventoryRepository {
  static const String _boxName = 'farm_organic_fertilizers_box';
  Future<Box> _getBox() async => await Hive.openBox(_boxName);

  @override
  Future<List<FarmOrganicFertilizerModel>> getAll() async {
    final box = await _getBox();
    final List<FarmOrganicFertilizerModel> list = [];
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map) list.add(FarmOrganicFertilizerModel.fromJson(val));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<FarmOrganicFertilizerModel?> getById(String id) async {
    final box = await _getBox();
    final val = box.get(id);
    if (val is Map) return FarmOrganicFertilizerModel.fromJson(val);
    return null;
  }

  @override
  Future<void> add(FarmOrganicFertilizerModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> update(FarmOrganicFertilizerModel record) async {
    final box = await _getBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}

