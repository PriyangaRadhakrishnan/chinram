class FarmFertilizerUsageModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String fertilizerId; // Associated chemical purchase batch
  final double bagsUsed; // decimal support
  final String? notes;
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const FarmFertilizerUsageModel({
    required this.id,
    required this.date,
    required this.fertilizerId,
    required this.bagsUsed,
    this.notes,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  FarmFertilizerUsageModel copyWith({
    String? id,
    String? date,
    String? fertilizerId,
    double? bagsUsed,
    String? notes,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return FarmFertilizerUsageModel(
      id: id ?? this.id,
      date: date ?? this.date,
      fertilizerId: fertilizerId ?? this.fertilizerId,
      bagsUsed: bagsUsed ?? this.bagsUsed,
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
      'fertilizerId': fertilizerId,
      'bagsUsed': bagsUsed,
      if (notes != null) 'notes': notes,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory FarmFertilizerUsageModel.fromJson(Map<dynamic, dynamic> json) {
    return FarmFertilizerUsageModel(
      id: json['id'] as String,
      date: json['date'] as String,
      fertilizerId: json['fertilizerId'] as String,
      bagsUsed: (json['bagsUsed'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
