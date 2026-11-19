import '../models/organic_fertilizer_model.dart';
import '../repositories/organic_fertilizer_repository.dart';

class OrganicFertilizerService {
  final OrganicFertilizerRepository _repository;

  const OrganicFertilizerService(this._repository);

  Future<List<OrganicFertilizerModel>> getAll() => _repository.getAll();
  Future<OrganicFertilizerModel?> getById(String id) => _repository.getById(id);
  Future<void> save(OrganicFertilizerModel record) => _repository.save(record);
  Future<void> delete(String id) => _repository.delete(id);
}
