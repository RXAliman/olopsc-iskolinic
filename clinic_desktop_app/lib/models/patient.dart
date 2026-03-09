class Patient {
  final String id;
  final String patientName;
  final String idNumber;
  final String address;
  final String guardianName;
  final String guardianContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  // CRDT fields
  final String hlc;
  final String nodeId;
  final bool isDeleted;

  Patient({
    required this.id,
    required this.patientName,
    required this.idNumber,
    this.address = '',
    this.guardianName = '',
    this.guardianContact = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.hlc = '',
    this.nodeId = '',
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'idNumber': idNumber,
      'address': address,
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hlc': hlc,
      'nodeId': nodeId,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      patientName: map['patientName'] as String,
      idNumber: map['idNumber'] as String,
      address: map['address'] as String? ?? '',
      guardianName: map['guardianName'] as String? ?? '',
      guardianContact: map['guardianContact'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      hlc: map['hlc'] as String? ?? '',
      nodeId: map['nodeId'] as String? ?? '',
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
    );
  }

  Patient copyWith({
    String? patientName,
    String? idNumber,
    String? address,
    String? guardianName,
    String? guardianContact,
    String? hlc,
    String? nodeId,
    bool? isDeleted,
  }) {
    return Patient(
      id: id,
      patientName: patientName ?? this.patientName,
      idNumber: idNumber ?? this.idNumber,
      address: address ?? this.address,
      guardianName: guardianName ?? this.guardianName,
      guardianContact: guardianContact ?? this.guardianContact,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      hlc: hlc ?? this.hlc,
      nodeId: nodeId ?? this.nodeId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Converts this patient to a JSON-compatible map for WebSocket sync.
  Map<String, dynamic> toSyncMap() => toMap();

  /// Creates a Patient from a sync payload received over WebSocket.
  factory Patient.fromSyncMap(Map<String, dynamic> map) => Patient.fromMap(map);
}
