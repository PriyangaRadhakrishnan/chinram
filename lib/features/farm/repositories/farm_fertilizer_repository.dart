import '../models/farm_fertilizer_model.dart';
import '../models/farm_organic_fertilizer_model.dart';
import '../models/farm_fertilizer_usage_model.dart';

abstract class FarmChemicalInventoryRepository {
  Future<List<FarmFertilizerModel>> getAll();
  Future<FarmFertilizerModel?> getById(String id);
  Future<void> add(FarmFertilizerModel record);
  Future<void> update(FarmFertilizerModel record);
  Future<void> delete(String id);
}

abstract class FarmChemicalUsageRepository {
  Future<List<FarmFertilizerUsageModel>> getAll();
  Future<FarmFertilizerUsageModel?> getById(String id);
  Future<void> add(FarmFertilizerUsageModel record);
  Future<void> update(FarmFertilizerUsageModel record);
  Future<void> delete(String id);
}

abstract class FarmOrganicInventoryRepository {
  Future<List<FarmOrganicFertilizerModel>> getAll();
  Future<FarmOrganicFertilizerModel?> getById(String id);
  Future<void> add(FarmOrganicFertilizerModel record);
  Future<void> update(FarmOrganicFertilizerModel record);
  Future<void> delete(String id);
}
