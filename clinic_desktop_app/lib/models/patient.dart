class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String middleName;
  final String extension;
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
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    this.extension = '',
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
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'extension': extension,
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
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      middleName: map['middleName'] as String? ?? '',
      extension: map['extension'] as String? ?? '',
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
    String? firstName,
    String? lastName,
    String? middleName,
    String? extension,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      extension: extension ?? this.extension,
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
