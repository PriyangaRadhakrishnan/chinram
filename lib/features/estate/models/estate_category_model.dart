class EstateCategoryModel {
  final String id;
  final String name;
  final List<String> subProducts;

  const EstateCategoryModel({
    required this.id,
    required this.name,
    this.subProducts = const [],
  });

  bool get hasSubProducts => subProducts.isNotEmpty;
}
