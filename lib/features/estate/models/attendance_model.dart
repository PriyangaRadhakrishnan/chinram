enum AttendanceStatus {
  present('Present'),
  absent('Absent');

  final String label;
  const AttendanceStatus(this.label);

  static AttendanceStatus fromString(String? value) {
    if (value == null) return AttendanceStatus.present;
    return AttendanceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => AttendanceStatus.present,
    );
  }
}

class WorkerAttendanceModel {
  final String workerId;
  final AttendanceStatus status;

  const WorkerAttendanceModel({
    required this.workerId,
    required this.status,
  });

  WorkerAttendanceModel copyWith({
    String? workerId,
    AttendanceStatus? status,
  }) {
    return WorkerAttendanceModel(
      workerId: workerId ?? this.workerId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'status': status.name,
    };
  }

  factory WorkerAttendanceModel.fromJson(Map<dynamic, dynamic> json) {
    return WorkerAttendanceModel(
      workerId: json['workerId'] as String,
      status: AttendanceStatus.fromString(json['status'] as String?),
    );
  }
}

class AttendanceModel {
  final String date; // format: yyyy-MM-dd
  final List<WorkerAttendanceModel> records;
  final String createdDate; // format: yyyy-MM-dd
  final String createdTime; // format: HH:mm:ss
  final String lastUpdatedDate; // format: yyyy-MM-dd
  final String lastUpdatedTime; // format: HH:mm:ss

  const AttendanceModel({
    required this.date,
    required this.records,
    required this.createdDate,
    required this.createdTime,
    required this.lastUpdatedDate,
    required this.lastUpdatedTime,
  });

  int get totalWorkers => records.length;
  int get presentCount => records.where((r) => r.status == AttendanceStatus.present).length;
  int get absentCount => records.where((r) => r.status == AttendanceStatus.absent).length;

  AttendanceModel copyWith({
    String? date,
    List<WorkerAttendanceModel>? records,
    String? createdDate,
    String? createdTime,
    String? lastUpdatedDate,
    String? lastUpdatedTime,
  }) {
    return AttendanceModel(
      date: date ?? this.date,
      records: records ?? this.records,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'records': records.map((r) => r.toJson()).toList(),
      'createdDate': createdDate,
      'createdTime': createdTime,
      'lastUpdatedDate': lastUpdatedDate,
      'lastUpdatedTime': lastUpdatedTime,
    };
  }

  factory AttendanceModel.fromJson(Map<dynamic, dynamic> json) {
    final recordsJson = json['records'] as List?;
    return AttendanceModel(
      date: json['date'] as String,
      records: recordsJson != null
          ? recordsJson.map((e) => WorkerAttendanceModel.fromJson(e as Map)).toList()
          : const [],
      createdDate: json['createdDate'] as String? ?? json['date'] as String? ?? '',
      createdTime: json['createdTime'] as String? ?? '00:00:00',
      lastUpdatedDate: json['lastUpdatedDate'] as String? ?? json['date'] as String? ?? '',
      lastUpdatedTime: json['lastUpdatedTime'] as String? ?? '00:00:00',
    );
  }
}
