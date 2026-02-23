class Patient {
  final String id;
  final String studentName;
  final String studentNumber;
  final String address;
  final String guardianName;
  final String guardianContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    this.address = '',
    this.guardianName = '',
    this.guardianContact = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'studentNumber': studentNumber,
      'address': address,
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      studentName: map['studentName'] as String,
      studentNumber: map['studentNumber'] as String,
      address: map['address'] as String? ?? '',
      guardianName: map['guardianName'] as String? ?? '',
      guardianContact: map['guardianContact'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Patient copyWith({
    String? studentName,
    String? studentNumber,
    String? address,
    String? guardianName,
    String? guardianContact,
  }) {
    return Patient(
      id: id,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      address: address ?? this.address,
      guardianName: guardianName ?? this.guardianName,
      guardianContact: guardianContact ?? this.guardianContact,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
