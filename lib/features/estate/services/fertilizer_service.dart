import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/fertilizer_transaction_model.dart';
import '../repositories/fertilizer_repository.dart';

class FertilizerService {
  final FertilizerRepository _repository;

  const FertilizerService(this._repository);

  Future<List<FertilizerModel>> getFertilizers() => _repository.getFertilizers();
  Future<FertilizerModel?> getFertilizerById(String id) => _repository.getFertilizerById(id);

  Future<void> saveFertilizer(FertilizerModel fertilizer, int initialStock) async {
    // Save inventory record
    await _repository.saveFertilizer(fertilizer);

    // Sync transaction ledger: delete any existing purchase transaction for this ID first
    await _repository.deleteTransactionsForReference(fertilizer.id);

    // Save a positive purchase ledger transaction
    final tx = FertilizerTransactionModel(
      id: '${fertilizer.id}_purchase_tx',
      fertilizerId: fertilizer.id,
      date: fertilizer.date,
      type: 'purchase',
      quantity: initialStock.toDouble(),
      referenceId: fertilizer.id,
      createdDate: fertilizer.createdDate,
      createdTime: fertilizer.createdTime,
    );
    await _repository.saveTransaction(tx);
  }

  Future<void> deleteFertilizer(String id) async {
    // Delete fertilizer inventory
    await _repository.deleteFertilizer(id);

    // Delete associated purchase ledger transactions
    await _repository.deleteTransactionsForReference(id);

    // Also delete all usage logs and their ledger transactions referencing this fertilizerId
    final usages = await _repository.getUsages();
    for (final usage in usages) {
      if (usage.fertilizerId == id) {
        await _repository.deleteUsage(usage.id);
        await _repository.deleteTransactionsForReference(usage.id);
      }
    }
  }

  Future<List<FertilizerUsageModel>> getUsages() => _repository.getUsages();
  Future<FertilizerUsageModel?> getUsageById(String id) => _repository.getUsageById(id);

  Future<void> saveUsage(FertilizerUsageModel usage) async {
    // Save usage log
    await _repository.saveUsage(usage);

    // Sync transaction ledger: delete any existing usage transaction for this ID
    await _repository.deleteTransactionsForReference(usage.id);

    // Save a negative usage ledger transaction
    final tx = FertilizerTransactionModel(
      id: '${usage.id}_usage_tx',
      fertilizerId: usage.fertilizerId,
      date: usage.date,
      type: 'usage',
      quantity: -usage.bagsUsed,
      referenceId: usage.id,
      createdDate: usage.createdDate,
      createdTime: usage.createdTime,
    );
    await _repository.saveTransaction(tx);
  }

  Future<void> deleteUsage(String id) async {
    // Delete usage record
    await _repository.deleteUsage(id);

    // Delete associated usage ledger transactions
    await _repository.deleteTransactionsForReference(id);
  }

  Future<List<FertilizerTransactionModel>> getTransactions() => _repository.getTransactions();

  // Dynamically calculate stock by aggregating transactions
  Future<double> getStockForFertilizer(String fertilizerId) async {
    final txs = await _repository.getTransactions();
    double total = 0.0;
    for (final tx in txs) {
      if (tx.fertilizerId == fertilizerId) {
        total += tx.quantity;
      }
    }
    return total;
  }
}
