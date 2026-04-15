class EmergencyAlert {
  final String id;
  final String studentId;
  final String studentName;
  final String studentNumber;
  final String message;
  final String location;
  final DateTime timestamp;
  final String status; // pending, acknowledged, resolved

  EmergencyAlert({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    this.message = '',
    this.location = '',
    DateTime? timestamp,
    this.status = 'pending',
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentNumber': studentNumber,
      'message': message,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory EmergencyAlert.fromMap(Map<String, dynamic> map) {
    return EmergencyAlert(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      studentNumber: map['studentNumber'] as String,
      message: map['message'] as String? ?? '',
      location: map['location'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: map['status'] as String? ?? 'pending',
    );
  }

  EmergencyAlert copyWith({String? status}) {
    return EmergencyAlert(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentNumber: studentNumber,
      message: message,
      location: location,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isResolved => status == 'resolved';
}
