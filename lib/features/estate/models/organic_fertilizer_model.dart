class OrganicFertilizerModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String name;
  final double loads;
  final String unit; // Tractor, Pickup, 407, Lorry
  final double price;
  final double totalPrice; // Equal to price
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const OrganicFertilizerModel({
    required this.id,
    required this.date,
    required this.name,
    required this.loads,
    required this.unit,
    required this.price,
    required this.totalPrice,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  OrganicFertilizerModel copyWith({
    String? id,
    String? date,
    String? name,
    double? loads,
    String? unit,
    double? price,
    double? totalPrice,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return OrganicFertilizerModel(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      loads: loads ?? this.loads,
      unit: unit ?? this.unit,
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
      'loads': loads,
      'unit': unit,
      'price': price,
      'totalPrice': totalPrice,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory OrganicFertilizerModel.fromJson(Map<dynamic, dynamic> json) {
    return OrganicFertilizerModel(
      id: json['id'] as String,
      date: json['date'] as String,
      name: json['name'] as String,
      loads: (json['loads'] as num).toDouble(),
      unit: json['unit'] as String,
      price: (json['price'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
