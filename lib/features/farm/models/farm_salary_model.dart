class FarmSalaryModel {
  final String id;
  final DateTime fromDate;
  final DateTime toDate;
  final String work;
  final int numberOfPersons;
  final double salaryAmount;
  final String? notes;
  final String createdDate;
  final String createdTime;
  final String lastUpdatedDate;
  final String lastUpdatedTime;

  const FarmSalaryModel({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.work,
    required this.numberOfPersons,
    required this.salaryAmount,
    this.notes,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  FarmSalaryModel copyWith({
    String? id,
    DateTime? fromDate,
    DateTime? toDate,
    String? work,
    int? numberOfPersons,
    double? salaryAmount,
    String? notes,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return FarmSalaryModel(
      id: id ?? this.id,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      work: work ?? this.work,
      numberOfPersons: numberOfPersons ?? this.numberOfPersons,
      salaryAmount: salaryAmount ?? this.salaryAmount,
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
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'work': work,
      'numberOfPersons': numberOfPersons,
      'salaryAmount': salaryAmount,
      'notes': notes,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory FarmSalaryModel.fromJson(Map<dynamic, dynamic> json) {
    return FarmSalaryModel(
      id: json['id'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      work: json['work'] as String,
      numberOfPersons: json['numberOfPersons'] as int,
      salaryAmount: (json['salaryAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
