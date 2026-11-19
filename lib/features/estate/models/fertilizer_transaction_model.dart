class FertilizerTransactionModel {
  final String id;
  final String fertilizerId; // Associated inventory purchase batch ID
  final String date; // format: yyyy-MM-dd
  final String type; // 'purchase' | 'usage'
  final double quantity; // Positive for purchase, negative for usage
  final String referenceId; // The ID of the FertilizerModel or FertilizerUsageModel
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss

  const FertilizerTransactionModel({
    required this.id,
    required this.fertilizerId,
    required this.date,
    required this.type,
    required this.quantity,
    required this.referenceId,
    required this.createdDate,
    required this.createdTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fertilizerId': fertilizerId,
      'date': date,
      'type': type,
      'quantity': quantity,
      'referenceId': referenceId,
      'createdDate': createdDate,
      'createdTime': createdTime,
    };
  }

  factory FertilizerTransactionModel.fromJson(Map<dynamic, dynamic> json) {
    return FertilizerTransactionModel(
      id: json['id'] as String,
      fertilizerId: json['fertilizerId'] as String,
      date: json['date'] as String,
      type: json['type'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      referenceId: json['referenceId'] as String,
      createdDate: json['createdDate'] as String,
      createdTime: json['createdTime'] as String,
    );
  }
}
