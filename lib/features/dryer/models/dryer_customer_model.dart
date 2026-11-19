enum DryerAreaType {
  acre('Acre'),
  plants('Plants');

  final String label;
  const DryerAreaType(this.label);

  static DryerAreaType? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final type in DryerAreaType.values) {
      if (type.name.toLowerCase() == normalized ||
          type.label.toLowerCase() == normalized) {
        return type;
      }
    }
    return null;
  }
}

class DryerCustomer {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final DryerAreaType areaType;
  final double areaValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DryerCustomer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.areaType,
    required this.areaValue,
    required this.createdAt,
    required this.updatedAt,
  });

  DryerCustomer copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? address,
    DryerAreaType? areaType,
    double? areaValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DryerCustomer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      areaType: areaType ?? this.areaType,
      areaValue: areaValue ?? this.areaValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'areaType': areaType.name,
      'areaValue': areaValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DryerCustomer.fromJson(Map<dynamic, dynamic> json) {
    return DryerCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: (json['address'] as String?) ?? '',
      areaType:
          DryerAreaType.fromString(json['areaType'] as String?) ??
          DryerAreaType.acre,
      areaValue: (json['areaValue'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
