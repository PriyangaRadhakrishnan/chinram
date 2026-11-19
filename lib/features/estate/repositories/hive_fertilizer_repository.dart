import 'package:hive/hive.dart';
import '../models/fertilizer_model.dart';
import '../models/fertilizer_usage_model.dart';
import '../models/fertilizer_transaction_model.dart';
import 'fertilizer_repository.dart';

class HiveFertilizerRepository implements FertilizerRepository {
  static const String _inventoryBoxName = 'fertilizer_inventory_box';
  static const String _usagesBoxName = 'fertilizer_usages_box';
  static const String _ledgerBoxName = 'fertilizer_ledger_box';

  Future<Box> _getInventoryBox() async => await Hive.openBox(_inventoryBoxName);
  Future<Box> _getUsagesBox() async => await Hive.openBox(_usagesBoxName);
  Future<Box> _getLedgerBox() async => await Hive.openBox(_ledgerBoxName);

  // Inventory
  @override
  Future<List<FertilizerModel>> getFertilizers() async {
    final box = await _getInventoryBox();
    final List<FertilizerModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(FertilizerModel.fromJson(value));
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
  Future<FertilizerModel?> getFertilizerById(String id) async {
    final box = await _getInventoryBox();
    final value = box.get(id);
    if (value is Map) {
      return FertilizerModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> saveFertilizer(FertilizerModel fertilizer) async {
    final box = await _getInventoryBox();
    await box.put(fertilizer.id, fertilizer.toJson());
  }

  @override
  Future<void> deleteFertilizer(String id) async {
    final box = await _getInventoryBox();
    await box.delete(id);
  }

  // Usages
  @override
  Future<List<FertilizerUsageModel>> getUsages() async {
    final box = await _getUsagesBox();
    final List<FertilizerUsageModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(FertilizerUsageModel.fromJson(value));
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
  Future<FertilizerUsageModel?> getUsageById(String id) async {
    final box = await _getUsagesBox();
    final value = box.get(id);
    if (value is Map) {
      return FertilizerUsageModel.fromJson(value);
    }
    return null;
  }

  @override
  Future<void> saveUsage(FertilizerUsageModel usage) async {
    final box = await _getUsagesBox();
    await box.put(usage.id, usage.toJson());
  }

  @override
  Future<void> deleteUsage(String id) async {
    final box = await _getUsagesBox();
    await box.delete(id);
  }

  // Transactions
  @override
  Future<List<FertilizerTransactionModel>> getTransactions() async {
    final box = await _getLedgerBox();
    final List<FertilizerTransactionModel> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(FertilizerTransactionModel.fromJson(value));
      }
    }
    return list;
  }

  @override
  Future<void> saveTransaction(FertilizerTransactionModel transaction) async {
    final box = await _getLedgerBox();
    await box.put(transaction.id, transaction.toJson());
  }

  @override
  Future<void> deleteTransactionsForReference(String referenceId) async {
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
