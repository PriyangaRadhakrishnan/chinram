import 'package:hive/hive.dart';
import '../models/tree_count_model.dart';
import '../models/tree_count_ledger_model.dart';
import 'tree_count_repository.dart';

class HiveTreeCountRepository implements TreeCountRepository {
  static const String _treeCountsBoxName = 'tree_counts_box';
  static const String _ledgerBoxName = 'tree_count_ledger_box';

  Future<Box> _getTreeCountsBox() async => await Hive.openBox(_treeCountsBoxName);
  Future<Box> _getLedgerBox() async => await Hive.openBox(_ledgerBoxName);

  @override
  Future<List<TreeCountModel>> getTreeCounts() async {
    final box = await _getTreeCountsBox();
    final List<TreeCountModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(TreeCountModel.fromJson(value));
      }
    }
    // Sort chronologically by date descending
    list.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.createdTime.compareTo(a.createdTime);
    });
    return list;
  }

  @override
  Future<TreeCountModel?> getTreeCountById(String id) async {
    final box = await _getTreeCountsBox();
    final value = box.get(id);
    if (value is Map) {
      return TreeCountModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> saveTreeCount(TreeCountModel record) async {
    final box = await _getTreeCountsBox();
    await box.put(record.id, record.toJson());
  }

  @override
  Future<void> deleteTreeCount(String id) async {
    final box = await _getTreeCountsBox();
    await box.delete(id);
  }

  @override
  Future<List<TreeCountLedgerModel>> getLedgerTransactions() async {
    final box = await _getLedgerBox();
    final List<TreeCountLedgerModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(TreeCountLedgerModel.fromJson(value));
      }
    }
    return list;
  }

  @override
  Future<void> saveLedgerTransaction(TreeCountLedgerModel transaction) async {
    final box = await _getLedgerBox();
    await box.put(transaction.id, transaction.toJson());
  }

  @override
  Future<void> deleteLedgerTransactionsForReference(String referenceId) async {
    final box = await _getLedgerBox();
    final List<dynamic> keysToDelete = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['referenceId'] == referenceId) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }
}
