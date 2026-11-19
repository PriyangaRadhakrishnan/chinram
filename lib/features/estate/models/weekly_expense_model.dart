class WeeklyExpenseModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String category; // 'Petrol' | 'Brush Cutter' | 'Maintenance' | 'Transport' | 'Others'
  final String? customCategoryName; // only populated if category is 'Others'
  final double amount;
  final String? notes;
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const WeeklyExpenseModel({
    required this.id,
    required this.date,
    required this.category,
    this.customCategoryName,
    required this.amount,
    this.notes,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  WeeklyExpenseModel copyWith({
    String? id,
    String? date,
    String? category,
    String? customCategoryName,
    double? amount,
    String? notes,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return WeeklyExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
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
      'category': category,
      'customCategoryName': customCategoryName,
      'amount': amount,
      'notes': notes,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory WeeklyExpenseModel.fromJson(Map<dynamic, dynamic> json) {
    return WeeklyExpenseModel(
      id: json['id'] as String,
      date: json['date'] as String,
      category: json['category'] as String,
      customCategoryName: json['customCategoryName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
