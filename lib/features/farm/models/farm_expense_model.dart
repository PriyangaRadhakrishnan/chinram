class OtherExpenseItem {
  final String name;
  final double amount;

  const OtherExpenseItem({
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  factory OtherExpenseItem.fromJson(Map<dynamic, dynamic> json) {
    return OtherExpenseItem(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class FarmExpenseModel {
  final String id;
  final DateTime date;
  final String category; // 'Coconut', 'Milk', 'Mango', 'Others'
  final String? subCategory; // For Milk: 'Feed', 'Grass', 'Doctor', 'Others'
  final double amount; // Total calculated expense
  final String? notes;

  // Coconut (Kai Vettu) specific fields
  final int? vettuWorkersCount;
  final double? vettuWorkerAmount;
  final int? chithuWorkersCount;
  final double? chithuWorkerAmount;
  final double? teaExpense;
  final List<OtherExpenseItem>? otherExpenses;

  // Milk / Feed / Grass / Others custom product name or purpose
  final String? productName;
  final double? quantity;
  final String? unit;

  const FarmExpenseModel({
    required this.id,
    required this.date,
    required this.category,
    this.subCategory,
    required this.amount,
    this.notes,
    this.vettuWorkersCount,
    this.vettuWorkerAmount,
    this.chithuWorkersCount,
    this.chithuWorkerAmount,
    this.teaExpense,
    this.otherExpenses,
    this.productName,
    this.quantity,
    this.unit,
  });

  FarmExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? subCategory,
    double? amount,
    String? notes,
    int? vettuWorkersCount,
    double? vettuWorkerAmount,
    int? chithuWorkersCount,
    double? chithuWorkerAmount,
    double? teaExpense,
    List<OtherExpenseItem>? otherExpenses,
    String? productName,
    double? quantity,
    String? unit,
  }) {
    return FarmExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      vettuWorkersCount: vettuWorkersCount ?? this.vettuWorkersCount,
      vettuWorkerAmount: vettuWorkerAmount ?? this.vettuWorkerAmount,
      chithuWorkersCount: chithuWorkersCount ?? this.chithuWorkersCount,
      chithuWorkerAmount: chithuWorkerAmount ?? this.chithuWorkerAmount,
      teaExpense: teaExpense ?? this.teaExpense,
      otherExpenses: otherExpenses ?? this.otherExpenses,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      'amount': amount,
      'notes': notes,
      if (vettuWorkersCount != null) 'vettuWorkersCount': vettuWorkersCount,
      if (vettuWorkerAmount != null) 'vettuWorkerAmount': vettuWorkerAmount,
      if (chithuWorkersCount != null) 'chithuWorkersCount': chithuWorkersCount,
      if (chithuWorkerAmount != null) 'chithuWorkerAmount': chithuWorkerAmount,
      if (teaExpense != null) 'teaExpense': teaExpense,
      if (otherExpenses != null) 'otherExpenses': otherExpenses!.map((e) => e.toJson()).toList(),
      if (productName != null) 'productName': productName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
    };
  }

  factory FarmExpenseModel.fromJson(Map<dynamic, dynamic> json) {
    return FarmExpenseModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      subCategory: json['subCategory'] as String?,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      vettuWorkersCount: json['vettuWorkersCount'] as int?,
      vettuWorkerAmount: json['vettuWorkerAmount'] != null ? (json['vettuWorkerAmount'] as num).toDouble() : null,
      chithuWorkersCount: json['chithuWorkersCount'] as int?,
      chithuWorkerAmount: json['chithuWorkerAmount'] != null ? (json['chithuWorkerAmount'] as num).toDouble() : null,
      teaExpense: json['teaExpense'] != null ? (json['teaExpense'] as num).toDouble() : null,
      otherExpenses: json['otherExpenses'] != null
          ? (json['otherExpenses'] as List).map((e) => OtherExpenseItem.fromJson(e as Map)).toList()
          : null,
      productName: json['productName'] as String?,
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : null,
      unit: json['unit'] as String?,
    );
  }
}
