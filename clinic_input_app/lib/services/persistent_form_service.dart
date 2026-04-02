/// A singleton service to persist form data and state during navigation.
///
/// This ensures that if the tablet loses connection and the user needs to
/// re-scan or go back to the welcome screen, their progress is not lost.
class PersistentFormService {
  static final PersistentFormService instance = PersistentFormService._internal();
  factory PersistentFormService() => instance;
  PersistentFormService._internal();

  bool get isEmpty => firstName.trim().isEmpty && lastName.trim().isEmpty;

  /// Update core patient fields from a data map (e.g. from desktop API).
  void updateFromMap(Map<String, dynamic> data) {
    firstName = data['firstName'] as String? ?? '';
    lastName = data['lastName'] as String? ?? '';
    middleName = data['middleName'] as String? ?? '';

    // Extension validation
    final incomingExt = data['extension'] as String? ?? 'None';
    const allowedExtensions = ['None', 'JR.', 'SR.', 'I', 'II', 'III'];
    if (allowedExtensions.contains(incomingExt)) {
      extension = incomingExt;
      customExtension = '';
    } else {
      extension = 'Others';
      customExtension = incomingExt;
    }

    if (data['birthdate'] != null) {
      birthdate = DateTime.tryParse(data['birthdate'] as String);
    }

    // Sex validation
    final incomingSex = data['sex'] as String? ?? 'Female';
    const allowedSex = ['Male', 'Female'];
    if (allowedSex.contains(incomingSex)) {
      sex = incomingSex;
      customSex = '';
    } else {
      sex = 'Others';
      customSex = incomingSex;
    }

    contactNumber = data['contactNumber'] as String? ?? '';
    address = data['address'] as String? ?? '';
    guardianName = data['guardianName'] as String? ?? '';
    guardianContact = data['guardianContact'] as String? ?? '';
    guardian2Name = data['guardian2Name'] as String? ?? '';
    guardian2Contact = data['guardian2Contact'] as String? ?? '';
    allergicTo = data['allergicTo'] as String? ?? '';
  }

  // ── Patient Info ─────────────────────────────────────────────────
  String studentNumber = '';
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String extension = 'None';
  String customExtension = '';
  DateTime? birthdate;
  String sex = 'Female';
  String customSex = '';
  String contactNumber = '';
  String address = '';
  String guardianName = '';
  String guardianContact = '';
  String guardian2Name = '';
  String guardian2Contact = '';
  String allergicTo = '';

  // ── Visitation Info ──────────────────────────────────────────────
  final Set<String> _selectedSymptoms = {};

  Set<String> get selectedSymptoms => _selectedSymptoms;

  void addSymptom(String symptom) => _selectedSymptoms.add(symptom);
  void removeSymptom(String symptom) => _selectedSymptoms.remove(symptom);
  void clearSymptoms() => _selectedSymptoms.clear();

  /// Resets all data in the persistence service. 
  /// Usually called after successful submission or manual form clear.
  void clear() {
    studentNumber = '';
    firstName = '';
    lastName = '';
    middleName = '';
    extension = 'None';
    customExtension = '';
    birthdate = null;
    sex = 'Female';
    customSex = '';
    contactNumber = '';
    address = '';
    guardianName = '';
    guardianContact = '';
    guardian2Name = '';
    guardian2Contact = '';
    allergicTo = '';
    _selectedSymptoms.clear();
  }
}
