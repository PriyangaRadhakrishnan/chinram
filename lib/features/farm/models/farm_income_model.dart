class FarmIncomeModel {
  final String id;
  final DateTime date;
  final String category; // 'Coconut', 'Mango', 'Milk', 'Others'
  final String productName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalAmount;
  final String? notes;
  final DateTime? fromDate; // For weekly milk entries
  final DateTime? toDate;   // For weekly milk entries

  const FarmIncomeModel({
    required this.id,
    required this.date,
    required this.category,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalAmount,
    this.notes,
    this.fromDate,
    this.toDate,
  });

  FarmIncomeModel copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? productName,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? totalAmount,
    String? notes,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return FarmIncomeModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
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
      if (fromDate != null) 'fromDate': fromDate!.toIso8601String(),
      if (toDate != null) 'toDate': toDate!.toIso8601String(),
    };
  }

  factory FarmIncomeModel.fromJson(Map<dynamic, dynamic> json) {
    return FarmIncomeModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      fromDate: json['fromDate'] != null ? DateTime.parse(json['fromDate'] as String) : null,
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate'] as String) : null,
    );
  }
}
