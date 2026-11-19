import '../models/estate_category_model.dart';
import 'category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  const MockCategoryRepository();

  @override
  Future<List<EstateCategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      EstateCategoryModel(
        id: 'coffee',
        name: 'Coffee',
        subProducts: ['Robusta Parchment', 'Robusta Urula'],
      ),
      EstateCategoryModel(
        id: 'pepper',
        name: 'Pepper',
        subProducts: ['Black Pepper', 'White Pepper', 'Green Pepper'],
      ),
      EstateCategoryModel(
        id: 'cardamom',
        name: 'Cardamom',
      ),
      EstateCategoryModel(
        id: 'arecanut',
        name: 'Areca Nut (Pakku)',
      ),
      EstateCategoryModel(
        id: 'avocado',
        name: 'Avocado',
      ),
      EstateCategoryModel(
        id: 'banana',
        name: 'Banana',
      ),
      EstateCategoryModel(
        id: 'clove',
        name: 'Clove (Kirambu)',
      ),
      EstateCategoryModel(
        id: 'nutmeg',
        name: 'Nutmeg (Jathika)',
        subProducts: ['Nutmeg Seed', 'Jathi Pathiri'],
      ),
      EstateCategoryModel(
        id: 'jackfruit',
        name: 'Jackfruit',
      ),
      EstateCategoryModel(
        id: 'others',
        name: 'Others',
      ),
    ];
  }
}
