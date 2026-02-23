class MedicalRecord {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final String filePath;
  final DateTime uploadedAt;
  final bool parentAcknowledged;
  final String parentNotes;

  MedicalRecord({
    required this.id,
    required this.studentId,
    required this.title,
    this.description = '',
    this.filePath = '',
    DateTime? uploadedAt,
    this.parentAcknowledged = false,
    this.parentNotes = '',
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'filePath': filePath,
      'uploadedAt': uploadedAt.toIso8601String(),
      'parentAcknowledged': parentAcknowledged ? 1 : 0,
      'parentNotes': parentNotes,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      parentAcknowledged: (map['parentAcknowledged'] as int? ?? 0) == 1,
      parentNotes: map['parentNotes'] as String? ?? '',
    );
  }

  MedicalRecord copyWith({
    String? title,
    String? description,
    String? filePath,
    bool? parentAcknowledged,
    String? parentNotes,
  }) {
    return MedicalRecord(
      id: id,
      studentId: studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt,
      parentAcknowledged: parentAcknowledged ?? this.parentAcknowledged,
      parentNotes: parentNotes ?? this.parentNotes,
    );
  }
}
