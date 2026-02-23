class EmergencyAlert {
  final String id;
  final String studentName;
  final String studentNumber;
  final String message;
  final DateTime timestamp;
  final bool acknowledged;

  EmergencyAlert({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    this.message = '',
    DateTime? timestamp,
    this.acknowledged = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'studentNumber': studentNumber,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged ? 1 : 0,
    };
  }

  factory EmergencyAlert.fromMap(Map<String, dynamic> map) {
    return EmergencyAlert(
      id: map['id'] as String,
      studentName: map['studentName'] as String,
      studentNumber: map['studentNumber'] as String,
      message: map['message'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      acknowledged: (map['acknowledged'] as int? ?? 0) == 1,
    );
  }

  EmergencyAlert copyWith({bool? acknowledged}) {
    return EmergencyAlert(
      id: id,
      studentName: studentName,
      studentNumber: studentNumber,
      message: message,
      timestamp: timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}
