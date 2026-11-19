import '../models/tree_count_model.dart';
import '../models/tree_count_ledger_model.dart';
import '../repositories/tree_count_repository.dart';

class TreeCountService {
  final TreeCountRepository _repository;

  const TreeCountService(this._repository);

  Future<List<TreeCountModel>> getTreeCounts() => _repository.getTreeCounts();
  Future<TreeCountModel?> getTreeCountById(String id) => _repository.getTreeCountById(id);

  Future<void> saveTreeCount(TreeCountModel record, int initialCount) async {
    // Save record
    await _repository.saveTreeCount(record);

    // Sync transaction ledger: delete any existing transaction for this reference ID
    await _repository.deleteLedgerTransactionsForReference(record.id);

    // Save a positive initial_count transaction
    final tx = TreeCountLedgerModel(
      id: '${record.id}_initial_tx',
      treeCountId: record.id,
      date: record.date,
      treeName: record.treeName,
      plotName: record.plotName,
      type: 'initial_count',
      quantity: initialCount,
      referenceId: record.id,
      createdDate: record.createdDate,
      createdTime: record.createdTime,
    );
    await _repository.saveLedgerTransaction(tx);
  }

  Future<void> deleteTreeCount(String id) async {
    // Delete tree record
    await _repository.deleteTreeCount(id);

    // Delete associated ledger transactions
    await _repository.deleteLedgerTransactionsForReference(id);
  }

  Future<List<TreeCountLedgerModel>> getLedgerTransactions() => _repository.getLedgerTransactions();

  // Dynamically calculate stock by aggregating transactions
  Future<int> getQuantityForTreeCount(String treeCountId) async {
    final txs = await _repository.getLedgerTransactions();
    int total = 0;
    for (final tx in txs) {
      if (tx.treeCountId == treeCountId) {
        total += tx.quantity;
      }
    }
    return total;
  }
}
