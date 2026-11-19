class TreeCuttingModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String? treeName;
  final String? placeName;
  final int? numberOfTrees;
  final double? pricePerTree;
  final double totalAmount; // Calculated or manually entered total
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const TreeCuttingModel({
    required this.id,
    required this.date,
    this.treeName,
    this.placeName,
    this.numberOfTrees,
    this.pricePerTree,
    required this.totalAmount,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  TreeCuttingModel copyWith({
    String? id,
    String? date,
    String? treeName,
    String? placeName,
    int? numberOfTrees,
    double? pricePerTree,
    double? totalAmount,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return TreeCuttingModel(
      id: id ?? this.id,
      date: date ?? this.date,
      treeName: treeName ?? this.treeName,
      placeName: placeName ?? this.placeName,
      numberOfTrees: numberOfTrees ?? this.numberOfTrees,
      pricePerTree: pricePerTree ?? this.pricePerTree,
      totalAmount: totalAmount ?? this.totalAmount,
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
      'treeName': treeName,
      'placeName': placeName,
      'numberOfTrees': numberOfTrees,
      'pricePerTree': pricePerTree,
      'totalAmount': totalAmount,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory TreeCuttingModel.fromJson(Map<dynamic, dynamic> json) {
    return TreeCuttingModel(
      id: json['id'] as String,
      date: json['date'] as String,
      treeName: json['treeName'] as String?,
      placeName: (json['placeName'] as String?) ?? (json['plotName'] as String?),
      numberOfTrees: json['numberOfTrees'] as int?,
      pricePerTree: json['pricePerTree'] != null ? (json['pricePerTree'] as num).toDouble() : null,
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : 0.0,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
