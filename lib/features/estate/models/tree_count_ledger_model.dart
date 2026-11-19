class TreeCountLedgerModel {
  final String id;
  final String treeCountId; // Associated tree count record ID
  final String date; // format: yyyy-MM-dd
  final String treeName;
  final String plotName;
  final String type; // 'initial_count' | 'cutting' | 'plantation'
  final int quantity; // Positive or negative
  final String referenceId; // The ID of the specific transaction creating it
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss

  const TreeCountLedgerModel({
    required this.id,
    required this.treeCountId,
    required this.date,
    required this.treeName,
    required this.plotName,
    required this.type,
    required this.quantity,
    required this.referenceId,
    required this.createdDate,
    required this.createdTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treeCountId': treeCountId,
      'date': date,
      'treeName': treeName,
      'plotName': plotName,
      'type': type,
      'quantity': quantity,
      'referenceId': referenceId,
      'createdDate': createdDate,
      'createdTime': createdTime,
    };
  }

  factory TreeCountLedgerModel.fromJson(Map<dynamic, dynamic> json) {
    return TreeCountLedgerModel(
      id: json['id'] as String,
      treeCountId: json['treeCountId'] as String,
      date: json['date'] as String,
      treeName: json['treeName'] as String,
      plotName: json['plotName'] as String,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      referenceId: json['referenceId'] as String,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
    );
  }
}
