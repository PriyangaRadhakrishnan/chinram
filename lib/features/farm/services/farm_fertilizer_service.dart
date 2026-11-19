import '../models/farm_fertilizer_model.dart';
import '../models/farm_organic_fertilizer_model.dart';
import '../models/farm_fertilizer_usage_model.dart';
import '../repositories/farm_fertilizer_repository.dart';

class FarmFertilizerService {
  final FarmChemicalInventoryRepository _chemicalInventory;
  final FarmChemicalUsageRepository _chemicalUsages;
  final FarmOrganicInventoryRepository _organicInventory;

  const FarmFertilizerService({
    required FarmChemicalInventoryRepository chemicalInventory,
    required FarmChemicalUsageRepository chemicalUsages,
    required FarmOrganicInventoryRepository organicInventory,
  })  : _chemicalInventory = chemicalInventory,
        _chemicalUsages = chemicalUsages,
        _organicInventory = organicInventory;

  // Chemical Inventory
  Future<List<FarmFertilizerModel>> getChemicalInventory() => _chemicalInventory.getAll();
  Future<FarmFertilizerModel?> getChemicalById(String id) => _chemicalInventory.getById(id);
  Future<void> addChemical(FarmFertilizerModel record) => _chemicalInventory.add(record);
  Future<void> updateChemical(FarmFertilizerModel record) => _chemicalInventory.update(record);
  Future<void> deleteChemical(String id) => _chemicalInventory.delete(id);

  // Chemical Usages
  Future<List<FarmFertilizerUsageModel>> getChemicalUsages() => _chemicalUsages.getAll();
  Future<FarmFertilizerUsageModel?> getChemicalUsageById(String id) => _chemicalUsages.getById(id);
  Future<void> addChemicalUsage(FarmFertilizerUsageModel record) => _chemicalUsages.add(record);
  Future<void> updateChemicalUsage(FarmFertilizerUsageModel record) => _chemicalUsages.update(record);
  Future<void> deleteChemicalUsage(String id) => _chemicalUsages.delete(id);

  // Organic Inventory
  Future<List<FarmOrganicFertilizerModel>> getOrganicInventory() => _organicInventory.getAll();
  Future<FarmOrganicFertilizerModel?> getOrganicById(String id) => _organicInventory.getById(id);
  Future<void> addOrganic(FarmOrganicFertilizerModel record) => _organicInventory.add(record);
  Future<void> updateOrganic(FarmOrganicFertilizerModel record) => _organicInventory.update(record);
  Future<void> deleteOrganic(String id) => _organicInventory.delete(id);
}
