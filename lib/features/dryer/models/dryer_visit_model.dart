enum DryerProduct {
  cardamom('Cardamom'),
  pepper('Pepper'),
  coffee('Coffee');

  final String label;
  const DryerProduct(this.label);

  static DryerProduct? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final product in DryerProduct.values) {
      if (product.name.toLowerCase() == normalized ||
          product.label.toLowerCase() == normalized) {
        return product;
      }
    }
    return null;
  }
}

class DryerVisit {
  final String id;
  final String customerId;
  final DateTime date;
  final double greenQuantity;
  final DryerProduct product;
  final double dryQuantity;
  final double percentage;
  final double rate;
  final double charges;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DryerVisit({
    required this.id,
    required this.customerId,
    required this.date,
    required this.greenQuantity,
    required this.product,
    required this.dryQuantity,
    required this.percentage,
    required this.rate,
    required this.charges,
    required this.createdAt,
    required this.updatedAt,
  });

  DryerVisit copyWith({
    String? id,
    String? customerId,
    DateTime? date,
    double? greenQuantity,
    DryerProduct? product,
    double? dryQuantity,
    double? percentage,
    double? rate,
    double? charges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DryerVisit(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      greenQuantity: greenQuantity ?? this.greenQuantity,
      product: product ?? this.product,
      dryQuantity: dryQuantity ?? this.dryQuantity,
      percentage: percentage ?? this.percentage,
      rate: rate ?? this.rate,
      charges: charges ?? this.charges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'greenQuantity': greenQuantity,
      'product': product.name,
      'dryQuantity': dryQuantity,
      'percentage': percentage,
      'rate': rate,
      'charges': charges,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DryerVisit.fromJson(Map<dynamic, dynamic> json) {
    return DryerVisit(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      date: DateTime.parse(json['date'] as String),
      greenQuantity: (json['greenQuantity'] as num).toDouble(),
      product:
          DryerProduct.fromString(json['product'] as String?) ??
          DryerProduct.cardamom,
      dryQuantity: (json['dryQuantity'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      charges: (json['charges'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Compares two visits so the newest visit sorts first.
  /// Compares calendar date first, then creation timestamp, then update timestamp.
  static int compareNewestFirst(DryerVisit a, DryerVisit b) {
    final aDay = DateTime(a.date.year, a.date.month, a.date.day);
    final bDay = DateTime(b.date.year, b.date.month, b.date.day);
    final dayCompare = bDay.compareTo(aDay);
    if (dayCompare != 0) return dayCompare;

    final createdCompare = b.createdAt.compareTo(a.createdAt);
    if (createdCompare != 0) return createdCompare;

    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) return updatedCompare;

    return b.id.compareTo(a.id);
  }
}
