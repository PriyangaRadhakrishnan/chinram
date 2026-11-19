import '../models/estate_income_model.dart';
import 'estate_income_repository.dart';

class MockEstateIncomeRepository implements EstateIncomeRepository {
  static final List<EstateIncomeModel> _records = [
    EstateIncomeModel(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Coffee',
      productName: 'Robusta Parchment',
      quantity: 150.0,
      unit: 'Kg',
      pricePerUnit: 180.0,
      totalAmount: 27000.0,
      notes: 'Premium grade harvest from Sector A.',
    ),
    EstateIncomeModel(
      id: '2',
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Pepper',
      productName: 'Black Pepper',
      quantity: 50.0,
      unit: 'Kg',
      pricePerUnit: 350.0,
      totalAmount: 17500.0,
      notes: 'Sun-dried and packaged.',
    ),
    EstateIncomeModel(
      id: '3',
      date: DateTime.now().subtract(const Duration(days: 12)),
      category: 'Cardamom',
      productName: 'Cardamom Green',
      quantity: 15.0,
      unit: 'Kg',
      pricePerUnit: 1200.0,
      totalAmount: 18000.0,
      notes: 'Sold at regional auctions.',
      greenQuantity: 90.0,
      dryQuantity: 15.0,
      percent: 6.00,
    ),
    EstateIncomeModel(
      id: '4',
      date: DateTime.now().subtract(const Duration(days: 20)),
      category: 'Areca Nut (Pakku)',
      productName: 'Dried Pakku',
      quantity: 80.0,
      unit: 'Kg',
      pricePerUnit: 250.0,
      totalAmount: 20000.0,
      notes: 'Bulk purchase by local vendor.',
    ),
  ];

  MockEstateIncomeRepository();

  @override
  Future<List<EstateIncomeModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_records);
  }

  @override
  Future<EstateIncomeModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(EstateIncomeModel income) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _records.add(income);
  }

  @override
  Future<void> update(EstateIncomeModel income) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _records.indexWhere((r) => r.id == income.id);
    if (index != -1) {
      _records[index] = income;
    }
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _records.removeWhere((r) => r.id == id);
  }
}
