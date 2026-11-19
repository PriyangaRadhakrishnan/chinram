class SalaryConfigurationModel {
  final double maleDailyWage;
  final double femaleDailyWage;

  const SalaryConfigurationModel({
    required this.maleDailyWage,
    required this.femaleDailyWage,
  });

  SalaryConfigurationModel copyWith({
    double? maleDailyWage,
    double? femaleDailyWage,
  }) {
    return SalaryConfigurationModel(
      maleDailyWage: maleDailyWage ?? this.maleDailyWage,
      femaleDailyWage: femaleDailyWage ?? this.femaleDailyWage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maleDailyWage': maleDailyWage,
      'femaleDailyWage': femaleDailyWage,
    };
  }

  factory SalaryConfigurationModel.fromJson(Map<dynamic, dynamic> json) {
    return SalaryConfigurationModel(
      maleDailyWage: (json['maleDailyWage'] as num?)?.toDouble() ?? 800.0,
      femaleDailyWage: (json['femaleDailyWage'] as num?)?.toDouble() ?? 700.0,
    );
  }
}
