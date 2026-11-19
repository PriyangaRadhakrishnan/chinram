import '../models/organic_fertilizer_model.dart';

abstract class OrganicFertilizerRepository {
  Future<List<OrganicFertilizerModel>> getAll();
  Future<OrganicFertilizerModel?> getById(String id);
  Future<void> save(OrganicFertilizerModel record);
  Future<void> delete(String id);
}
