class Visitation {
  final String id;
  final String studentId;
  final DateTime dateTime;
  final List<String> symptoms;
  final String treatment;
  final String remarks;
  final DateTime? followUpDate;
  final bool followUpCompleted;
  final String followUpNotes;

  Visitation({
    required this.id,
    required this.studentId,
    DateTime? dateTime,
    this.symptoms = const [],
    this.treatment = '',
    this.remarks = '',
    this.followUpDate,
    this.followUpCompleted = false,
    this.followUpNotes = '',
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'dateTime': dateTime.toIso8601String(),
      'symptoms': symptoms.join('|'),
      'treatment': treatment,
      'remarks': remarks,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpCompleted': followUpCompleted ? 1 : 0,
      'followUpNotes': followUpNotes,
    };
  }

  factory Visitation.fromMap(Map<String, dynamic> map) {
    final symptomsStr = map['symptoms'] as String? ?? '';
    return Visitation(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      symptoms: symptomsStr.isEmpty ? [] : symptomsStr.split('|'),
      treatment: map['treatment'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      followUpDate: map['followUpDate'] != null
          ? DateTime.parse(map['followUpDate'] as String)
          : null,
      followUpCompleted: (map['followUpCompleted'] as int? ?? 0) == 1,
      followUpNotes: map['followUpNotes'] as String? ?? '',
    );
  }

  Visitation copyWith({bool? followUpCompleted, String? followUpNotes}) {
    return Visitation(
      id: id,
      studentId: studentId,
      dateTime: dateTime,
      symptoms: symptoms,
      treatment: treatment,
      remarks: remarks,
      followUpDate: followUpDate,
      followUpCompleted: followUpCompleted ?? this.followUpCompleted,
      followUpNotes: followUpNotes ?? this.followUpNotes,
    );
  }
}
