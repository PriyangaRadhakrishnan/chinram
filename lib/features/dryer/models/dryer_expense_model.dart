class DryerExpense {
  final String id;
  final DateTime date;
  final String category;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DryerExpense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DryerExpense copyWith({
    String? id,
    DateTime? date,
    String? category,
    double? amount,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DryerExpense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DryerExpense.fromJson(Map<dynamic, dynamic> json) {
    final id = json['id'];
    final dateStr = json['date'];
    final category = json['category'];
    final amountRaw = json['amount'];
    final notesRaw = json['notes'];
    final createdAtStr = json['createdAt'];
    final updatedAtStr = json['updatedAt'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Invalid dryer expense id');
    }
    if (dateStr is! String) {
      throw const FormatException('Invalid dryer expense date');
    }
    if (category is! String || category.trim().isEmpty) {
      throw const FormatException('Invalid dryer expense category');
    }
    if (amountRaw is! num || !amountRaw.toDouble().isFinite || amountRaw <= 0) {
      throw const FormatException('Invalid dryer expense amount');
    }
    if (notesRaw != null && notesRaw is! String) {
      throw const FormatException('Invalid dryer expense notes');
    }
    if (createdAtStr is! String || updatedAtStr is! String) {
      throw const FormatException('Invalid dryer expense timestamps');
    }

    final trimmedNotes = notesRaw?.trim();

    return DryerExpense(
      id: id,
      date: DateTime.parse(dateStr),
      category: category.trim(),
      amount: amountRaw.toDouble(),
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  /// Compares two expenses so the newest expense sorts first.
  /// Compares calendar date first, then creation timestamp, then update timestamp.
  static int compareNewestFirst(DryerExpense a, DryerExpense b) {
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
