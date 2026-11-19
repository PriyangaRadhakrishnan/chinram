class ManagerSalaryModel {
  final String id;
  final String fromDate; // yyyy-MM-dd
  final String toDate; // yyyy-MM-dd
  final double weeklySalary;
  final String createdDate; // yyyy-MM-dd
  final String createdTime; // HH:mm:ss
  final String lastUpdatedDate; // yyyy-MM-dd
  final String lastUpdatedTime; // HH:mm:ss

  const ManagerSalaryModel({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.weeklySalary,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  ManagerSalaryModel copyWith({
    String? id,
    String? fromDate,
    String? toDate,
    double? weeklySalary,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return ManagerSalaryModel(
      id: id ?? this.id,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      weeklySalary: weeklySalary ?? this.weeklySalary,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromDate': fromDate,
      'toDate': toDate,
      'weeklySalary': weeklySalary,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory ManagerSalaryModel.fromJson(Map<dynamic, dynamic> json) {
    return ManagerSalaryModel(
      id: json['id'] as String,
      fromDate: json['fromDate'] as String,
      toDate: json['toDate'] as String,
      weeklySalary: (json['weeklySalary'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
