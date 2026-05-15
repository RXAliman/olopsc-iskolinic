import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../providers/patient_provider.dart';
import '../providers/inventory_provider.dart';
import '../constants/symptoms.dart';

class MockDataService {
  static final Random _random = Random();
  static const Uuid _uuid = Uuid();

  static const List<String> _firstNames = [
    'JUAN',
    'MARIA',
    'JOSE',
    'ANA',
    'PEDRO',
    'ROSA',
    'CARLOS',
    'ELENA',
    'MIGUEL',
    'SOFIA',
    'GABRIEL',
    'ISABELLA',
    'RAFAEL',
    'CARMEN',
    'ANTONIO',
    'LUCIA',
    'FERNANDO',
    'DANIELA',
    'MARCO',
    'PATRICIA',
    'ANDREA',
    'RICO',
    'JASMINE',
    'ANGELO',
  ];

  static const List<String> _lastNames = [
    'DE LA CRUZ',
    'SANTOS',
    'REYES',
    'GARCIA',
    'CRUZ',
    'MENDOZA',
    'TORRES',
    'GONZALES',
    'RAMOS',
    'AQUINO',
    'VILLANUEVA',
    'CASTILLO',
    'RIVERA',
    'FERNANDEZ',
    'LOPEZ',
    'MARTINEZ',
    'PASCUAL',
    'BAUTISTA',
  ];

  static const List<String> _departments = [
    'Pre-school',
    'Grade School',
    'Junior High School',
    'Senior High School',
    'College',
  ];

  static const List<String> _treatments = [
    'Rest and observation',
    'Applied first aid',
    'Referred to physician',
    'Medication administered',
    'Cold compress applied',
    'Wound cleaned and dressed',
    'Sent home for rest',
    'Referred to hospital',
    'Monitored in clinic',
  ];

  static const List<(String, String)> _defaultSupplies = [
    ('Alcohol', 'bottle'),
    ('Cotton Balls', 'piece'),
    ('Band-Aid', 'piece'),
    ('Betadine', 'bottle'),
    ('Gauze', 'piece'),
    ('Medical Tape', 'piece'),
    ('Paracetamol', 'piece'),
    ('Ibuprofen', 'piece'),
    ('Thermometer Cover', 'piece'),
    ('Ice Pack', 'piece'),
  ];

  static const String mockNodeId = 'MOCK_NODE';

  static Patient generateMockPatient({DateTime? createdAt}) {
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    final role = _random.nextDouble() < 0.8 ? 'Student' : 'Employee';
    final department = role == 'Student'
        ? _departments[_random.nextInt(_departments.length)]
        : 'General';

    String level = '';
    if (role == 'Student') {
      final List<String> levels;
      switch (department) {
        case 'Pre-school':
          levels = ['Nursery', 'Pre-Kinder', 'Kinder'];
          break;
        case 'Grade School':
          levels = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];
          break;
        case 'Junior High School':
          levels = ['Grade 7', 'Grade 8', 'Grade 9', 'Grade 10'];
          break;
        case 'Senior High School':
          levels = ['Grade 11', 'Grade 12'];
          break;
        case 'College':
          levels = ['First Year', 'Second Year', 'Third Year', 'Fourth Year'];
          break;
        default:
          levels = [];
      }
      if (levels.isNotEmpty) {
        level = levels[_random.nextInt(levels.length)];
      }
    }

    final idNumber = 'MOCK-${_uuid.v4().substring(0, 8).toUpperCase()}';

    // Birthdate between 5 and 25 years ago depending on department
    int baseAge = 5;
    if (department == 'Junior High School') baseAge = 12;
    if (department == 'Senior High School') baseAge = 16;
    if (department == 'College') baseAge = 18;
    if (department == 'General') baseAge = 25;

    final birthdate = DateTime.now().subtract(
      Duration(days: 365 * (baseAge + _random.nextInt(10))),
    );

    return Patient(
      id: _uuid.v4(),
      firstName: firstName,
      lastName: lastName,
      patientName: '$lastName, $firstName',
      idNumber: idNumber,
      birthdate: birthdate,
      sex: _random.nextBool() ? 'Male' : 'Female',
      role: role,
      department: department,
      level: level,
      contactNumber:
          '09${_random.nextInt(100000000).toString().padLeft(9, '0')}',
      address: 'Mock Street, Barangay ${_random.nextInt(100)}, City',
      guardianName: 'Guardian of $firstName',
      guardianContact:
          '09${_random.nextInt(100000000).toString().padLeft(9, '0')}',
      createdAt: createdAt,
      nodeId: mockNodeId,
    );
  }

  static Visitation generateMockVisitation(
    String patientId, {
    DateTime? dateTime,
  }) {
    final numSymptoms = _random.nextInt(3) + 1;
    final symptoms = <String>[];
    for (int i = 0; i < numSymptoms; i++) {
      symptoms.add(kSymptomsList[_random.nextInt(kSymptomsList.length)]);
    }

    return Visitation(
      id: _uuid.v4(),
      patientId: patientId,
      dateTime:
          dateTime ??
          DateTime.now().subtract(
            Duration(minutes: _random.nextInt(1440)),
          ), // Within last 24h by default
      symptoms: symptoms,
      treatment: _treatments[_random.nextInt(_treatments.length)],
      remarks: 'Mock visitation for testing.',
      nodeId: mockNodeId,
    );
  }

  static Future<void> bulkGeneratePatients(
    PatientProvider provider,
    int count, {
    int? year,
  }) async {
    final patients = <Patient>[];
    for (int i = 0; i < count; i++) {
      DateTime? createdAt;
      if (year != null) {
        // Random date within that year
        final start = DateTime(year, 1, 1);
        final end = DateTime(year, 12, 31);
        final range = end.difference(start).inDays;
        createdAt = start.add(Duration(days: _random.nextInt(range)));
      }
      patients.add(generateMockPatient(createdAt: createdAt));
    }
    await provider.addPatientsBatch(patients);
  }

  static Future<void> bulkGenerateVisits(
    PatientProvider provider,
    String patientId,
    int count, {
    int daysBack = 0,
  }) async {
    final visits = <Visitation>[];
    for (int i = 0; i < count; i++) {
      DateTime? dt;
      if (daysBack > 0) {
        dt = DateTime.now().subtract(
          Duration(
            days: _random.nextInt(daysBack),
            hours: _random.nextInt(24),
            minutes: _random.nextInt(60),
          ),
        );
      }
      visits.add(generateMockVisitation(patientId, dateTime: dt));
    }
    await provider.addVisitationsBatch(visits);
  }

  static Future<void> bulkGenerateVisitsForMultiplePatients(
    PatientProvider provider,
    List<String> patientIds,
    int countPerPatient, {
    int daysBack = 0,
  }) async {
    final allVisits = <Visitation>[];
    for (final patientId in patientIds) {
      for (int i = 0; i < countPerPatient; i++) {
        DateTime? dt;
        if (daysBack > 0) {
          dt = DateTime.now().subtract(
            Duration(
              days: _random.nextInt(daysBack),
              hours: _random.nextInt(24),
              minutes: _random.nextInt(60),
            ),
          );
        }
        allVisits.add(generateMockVisitation(patientId, dateTime: dt));
      }
    }
    await provider.addVisitationsBatch(allVisits);
  }

  static Future<void> seedDefaultInventory(InventoryProvider provider) async {
    final clinics = ['Clinic A', 'Clinic B'];
    for (final clinic in clinics) {
      for (final supply in _defaultSupplies) {
        final name = supply.$1;
        final type = supply.$2;

        // Check if already exists to avoid duplicates if seeded multiple times
        final exists = provider.allItems.any(
          (item) => item.itemName == name && item.clinic == clinic,
        );
        if (exists) continue;

        await provider.addNewSupplyItem(
          itemName: name,
          lowStockAmount: 10,
          clinic: clinic,
          itemType: type,
          initialStocks: [
            (amount: 50, expiry: DateTime.now().add(Duration(days: 365))),
            (amount: 20, expiry: DateTime.now().add(Duration(days: 180))),
          ],
          nodeId: mockNodeId,
        );
      }
    }
  }
}
