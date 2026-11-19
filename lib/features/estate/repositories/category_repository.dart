import '../models/estate_category_model.dart';

abstract class CategoryRepository {
  Future<List<EstateCategoryModel>> getCategories();
}
