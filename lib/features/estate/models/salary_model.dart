class SalaryModel {
  final String id;
  final String workerId;
  final String period; // e.g. "July 2026"
  final String startDate; // format: yyyy-MM-dd
  final String endDate; // format: yyyy-MM-dd
  final String calculationMethod; // 'attendance' | 'manual'
  final String durationUnit; // 'days' | 'weeks' | 'months'
  final int durationValue; // manual unit count
  final int presentDays; // present count from attendance
  final double dailyWage; // daily wage applied at time of generation
  final double totalSalary; // total calculated amount
  final String paymentStatus; // 'pending' | 'paid'
  final String? paymentDate; // format: yyyy-MM-dd
  final String? paymentTime; // format: HH:mm:ss
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const SalaryModel({
    required this.id,
    required this.workerId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.calculationMethod,
    required this.durationUnit,
    required this.durationValue,
    required this.presentDays,
    required this.dailyWage,
    required this.totalSalary,
    required this.paymentStatus,
    this.paymentDate,
    this.paymentTime,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  SalaryModel copyWith({
    String? id,
    String? workerId,
    String? period,
    String? startDate,
    String? endDate,
    String? calculationMethod,
    String? durationUnit,
    int? durationValue,
    int? presentDays,
    double? dailyWage,
    double? totalSalary,
    String? paymentStatus,
    String? paymentDate,
    String? paymentTime,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return SalaryModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      durationUnit: durationUnit ?? this.durationUnit,
      durationValue: durationValue ?? this.durationValue,
      presentDays: presentDays ?? this.presentDays,
      dailyWage: dailyWage ?? this.dailyWage,
      totalSalary: totalSalary ?? this.totalSalary,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentTime: paymentTime ?? this.paymentTime,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'calculationMethod': calculationMethod,
      'durationUnit': durationUnit,
      'durationValue': durationValue,
      'presentDays': presentDays,
      'dailyWage': dailyWage,
      'totalSalary': totalSalary,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate,
      'paymentTime': paymentTime,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory SalaryModel.fromJson(Map<dynamic, dynamic> json) {
    return SalaryModel(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      period: json['period'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      calculationMethod: json['calculationMethod'] as String,
      durationUnit: json['durationUnit'] as String,
      durationValue: json['durationValue'] as int,
      presentDays: json['presentDays'] as int,
      dailyWage: (json['dailyWage'] as num).toDouble(),
      totalSalary: (json['totalSalary'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      paymentDate: json['paymentDate'] as String?,
      paymentTime: json['paymentTime'] as String?,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
