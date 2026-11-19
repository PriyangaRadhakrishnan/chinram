import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/fertilizer_transaction_model.dart';

abstract class FertilizerRepository {
  // Inventory
  Future<List<FertilizerModel>> getFertilizers();
  Future<FertilizerModel?> getFertilizerById(String id);
  Future<void> saveFertilizer(FertilizerModel fertilizer);
  Future<void> deleteFertilizer(String id);

  // Usages
  Future<List<FertilizerUsageModel>> getUsages();
  Future<FertilizerUsageModel?> getUsageById(String id);
  Future<void> saveUsage(FertilizerUsageModel usage);
  Future<void> deleteUsage(String id);

  // Transactions
  Future<List<FertilizerTransactionModel>> getTransactions();
  Future<void> saveTransaction(FertilizerTransactionModel transaction);
  Future<void> deleteTransactionsForReference(String referenceId);
}
