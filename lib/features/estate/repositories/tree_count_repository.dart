import '../models/tree_count_model.dart';
import '../models/tree_count_ledger_model.dart';

abstract class TreeCountRepository {
  Future<List<TreeCountModel>> getTreeCounts();
  Future<TreeCountModel?> getTreeCountById(String id);
  Future<void> saveTreeCount(TreeCountModel record);
  Future<void> deleteTreeCount(String id);

  Future<List<TreeCountLedgerModel>> getLedgerTransactions();
  Future<void> saveLedgerTransaction(TreeCountLedgerModel transaction);
  Future<void> deleteLedgerTransactionsForReference(String referenceId);
}
