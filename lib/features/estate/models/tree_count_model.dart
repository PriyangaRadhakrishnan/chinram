class TreeCountModel {
  final String id;
  final String date; // format: yyyy-MM-dd
  final String treeName;
  final String plotName; // 'Plot A' | 'Plot B' | 'Plot C' | 'Plot D'
  final int initialCount;
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const TreeCountModel({
    required this.id,
    required this.date,
    required this.treeName,
    required this.plotName,
    required this.initialCount,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  TreeCountModel copyWith({
    String? id,
    String? date,
    String? treeName,
    String? plotName,
    int? initialCount,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return TreeCountModel(
      id: id ?? this.id,
      date: date ?? this.date,
      treeName: treeName ?? this.treeName,
      plotName: plotName ?? this.plotName,
      initialCount: initialCount ?? this.initialCount,
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
      'plotName': plotName,
      'initialCount': initialCount,
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory TreeCountModel.fromJson(Map<dynamic, dynamic> json) {
    return TreeCountModel(
      id: json['id'] as String,
      date: json['date'] as String,
      treeName: json['treeName'] as String,
      plotName: json['plotName'] as String,
      initialCount: json['initialCount'] as int,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
      lastUpdatedDate: json['lastUpdatedDate'] as String,
      lastUpdatedTime: json['lastUpdatedTime'] as String,
    );
  }
}
