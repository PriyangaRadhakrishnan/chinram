class EstateIncomeModel {
  final String id;
  final DateTime date;
  final String category;
  final String productName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalAmount;
  final String? notes;
  final double? greenQuantity;
  final double? dryQuantity;
  final double? percent;

  const EstateIncomeModel({
    required this.id,
    required this.date,
    required this.category,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalAmount,
    this.notes,
    this.greenQuantity,
    this.dryQuantity,
    this.percent,
  });

  EstateIncomeModel copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? productName,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? totalAmount,
    String? notes,
    double? greenQuantity,
    double? dryQuantity,
    double? percent,
  }) {
    return EstateIncomeModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      greenQuantity: greenQuantity ?? this.greenQuantity,
      dryQuantity: dryQuantity ?? this.dryQuantity,
      percent: percent ?? this.percent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'notes': notes,
      if (greenQuantity != null) 'greenQuantity': greenQuantity,
      if (dryQuantity != null) 'dryQuantity': dryQuantity,
      if (percent != null) 'percent': percent,
    };
  }

  factory EstateIncomeModel.fromJson(Map<dynamic, dynamic> json) {
    return EstateIncomeModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      greenQuantity: json['greenQuantity'] != null ? (json['greenQuantity'] as num).toDouble() : null,
      dryQuantity: json['dryQuantity'] != null ? (json['dryQuantity'] as num).toDouble() : null,
      percent: json['percent'] != null ? (json['percent'] as num).toDouble() : null,
    );
  }
}
