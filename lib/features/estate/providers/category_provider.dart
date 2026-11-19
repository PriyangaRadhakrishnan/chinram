import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estate_category_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/mock_category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return const MockCategoryRepository();
});

final categoriesFutureProvider = FutureProvider<List<EstateCategoryModel>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});
