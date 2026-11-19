class FertilizerModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String name;
  final double quantityPerBag;
  final String unit; // display only "Kg", read-only
  final int initialStock; // starting bags count (to be populated in initial transaction)
  final double price;
  final double totalPrice; // Equal to price
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const FertilizerModel({
    required this.id,
    required this.date,
    required this.name,
    required this.quantityPerBag,
    required this.unit,
    required this.initialStock,
    required this.price,
    required this.totalPrice,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  FertilizerModel copyWith({
    String? id,
    String? date,
    String? name,
    double? quantityPerBag,
    String? unit,
    int? initialStock,
    double? price,
    double? totalPrice,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return FertilizerModel(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      quantityPerBag: quantityPerBag ?? this.quantityPerBag,
      unit: unit ?? this.unit,
      initialStock: initialStock ?? this.initialStock,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'quantityPerBag': quantityPerBag,
      'unit': unit,
      'initialStock': initialStock,
      'price': price,
      'totalPrice': totalPrice,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory FertilizerModel.fromJson(Map<dynamic, dynamic> json) {
    return FertilizerModel(
      id: json['id'] as String,
      date: json['date'] as String,
      name: json['name'] as String,
      quantityPerBag: (json['quantityPerBag'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'Kg',
      initialStock: json['initialStock'] as int? ?? 0,
      price: (json['price'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
