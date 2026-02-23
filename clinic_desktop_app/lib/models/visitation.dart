class Visitation {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final List<String> symptoms;
  final String treatment;
  final String remarks;

  Visitation({
    required this.id,
    required this.patientId,
    DateTime? dateTime,
    this.symptoms = const [],
    this.treatment = '',
    this.remarks = '',
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'symptoms': symptoms.join('|'),
      'treatment': treatment,
      'remarks': remarks,
    };
  }

  factory Visitation.fromMap(Map<String, dynamic> map) {
    final symptomsStr = map['symptoms'] as String? ?? '';
    return Visitation(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      symptoms: symptomsStr.isEmpty ? [] : symptomsStr.split('|'),
      treatment: map['treatment'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
    );
  }
}
