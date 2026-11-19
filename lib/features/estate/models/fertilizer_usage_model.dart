class FertilizerUsageModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String fertilizerId; // associated purchase batch
  final double bagsUsed;
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const FertilizerUsageModel({
    required this.id,
    required this.date,
    required this.fertilizerId,
    required this.bagsUsed,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  FertilizerUsageModel copyWith({
    String? id,
    String? date,
    String? fertilizerId,
    double? bagsUsed,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return FertilizerUsageModel(
      id: id ?? this.id,
      date: date ?? this.date,
      fertilizerId: fertilizerId ?? this.fertilizerId,
      bagsUsed: bagsUsed ?? this.bagsUsed,
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
      'fertilizerId': fertilizerId,
      'bagsUsed': bagsUsed,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory FertilizerUsageModel.fromJson(Map<dynamic, dynamic> json) {
    return FertilizerUsageModel(
      id: json['id'] as String,
      date: json['date'] as String,
      fertilizerId: json['fertilizerId'] as String,
      bagsUsed: (json['bagsUsed'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
