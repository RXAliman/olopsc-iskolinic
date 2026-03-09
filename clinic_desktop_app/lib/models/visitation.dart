class Visitation {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final List<String> symptoms;
  final List<String> suppliesUsed;
  final String treatment;
  final String remarks;

  // CRDT fields
  final String hlc;
  final String nodeId;
  final bool isDeleted;

  Visitation({
    required this.id,
    required this.patientId,
    DateTime? dateTime,
    this.symptoms = const [],
    this.suppliesUsed = const [],
    this.treatment = '',
    this.remarks = '',
    this.hlc = '',
    this.nodeId = '',
    this.isDeleted = false,
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'symptoms': symptoms.join('|'),
      'suppliesUsed': suppliesUsed.join('|'),
      'treatment': treatment,
      'remarks': remarks,
      'hlc': hlc,
      'nodeId': nodeId,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory Visitation.fromMap(Map<String, dynamic> map) {
    final symptomsStr = map['symptoms'] as String? ?? '';
    final suppliesStr = map['suppliesUsed'] as String? ?? '';
    return Visitation(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      symptoms: symptomsStr.isEmpty ? [] : symptomsStr.split('|'),
      suppliesUsed: suppliesStr.isEmpty ? [] : suppliesStr.split('|'),
      treatment: map['treatment'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      hlc: map['hlc'] as String? ?? '',
      nodeId: map['nodeId'] as String? ?? '',
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
    );
  }

  /// Converts this visitation to a JSON-compatible map for WebSocket sync.
  Map<String, dynamic> toSyncMap() => toMap();

  /// Creates a Visitation from a sync payload received over WebSocket.
  factory Visitation.fromSyncMap(Map<String, dynamic> map) =>
      Visitation.fromMap(map);
}
