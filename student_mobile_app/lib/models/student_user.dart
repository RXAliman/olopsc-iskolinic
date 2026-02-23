class StudentUser {
  final String id;
  final String studentName;
  final String studentNumber;
  final String email;
  final String phone;
  final String guardianName;
  final String guardianEmail;
  final DateTime createdAt;

  StudentUser({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    required this.email,
    this.phone = '',
    this.guardianName = '',
    this.guardianEmail = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'studentNumber': studentNumber,
      'email': email,
      'phone': phone,
      'guardianName': guardianName,
      'guardianEmail': guardianEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudentUser.fromMap(Map<String, dynamic> map) {
    return StudentUser(
      id: map['id'] as String,
      studentName: map['studentName'] as String,
      studentNumber: map['studentNumber'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      guardianName: map['guardianName'] as String? ?? '',
      guardianEmail: map['guardianEmail'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  StudentUser copyWith({
    String? studentName,
    String? studentNumber,
    String? email,
    String? phone,
    String? guardianName,
    String? guardianEmail,
  }) {
    return StudentUser(
      id: id,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      createdAt: createdAt,
    );
  }
}
