enum WorkerGender {
  male('Male'),
  female('Female');

  final String label;
  const WorkerGender(this.label);

  static WorkerGender? fromString(String? value) {
    if (value == null) return null;
    return WorkerGender.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => WorkerGender.male,
    );
  }
}

enum WorkerStatus {
  active('Active'),
  inactive('Inactive');

  final String label;
  const WorkerStatus(this.label);

  static WorkerStatus? fromString(String? value) {
    if (value == null) return null;
    return WorkerStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => WorkerStatus.active,
    );
  }
}

class WorkerModel {
  final String id;
  final String? name;
  final WorkerGender gender;
  final String? phoneNumber;
  final WorkerStatus status;
  final String? notes;

  const WorkerModel({
    required this.id,
    this.name,
    required this.gender,
    this.phoneNumber,
    required this.status,
    this.notes,
  });

  WorkerModel copyWith({
    String? id,
    String? name,
    WorkerGender? gender,
    String? phoneNumber,
    WorkerStatus? status,
    String? notes,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender.name,
      'phoneNumber': phoneNumber,
      'status': status.name,
      'notes': notes,
    };
  }

  factory WorkerModel.fromJson(Map<dynamic, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      gender: WorkerGender.fromString(json['gender'] as String?) ?? WorkerGender.male,
      phoneNumber: json['phoneNumber'] as String?,
      status: WorkerStatus.fromString(json['status'] as String?) ?? WorkerStatus.active,
      notes: json['notes'] as String?,
    );
  }
}
