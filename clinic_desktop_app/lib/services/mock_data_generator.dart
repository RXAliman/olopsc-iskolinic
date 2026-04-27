import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../models/inventory_item.dart';
import '../constants/symptoms.dart';
import '../crdt/hlc.dart';
import 'database_helper.dart';

class MockDataGenerator {
  static final _random = Random();
  static const _uuid = Uuid();

  static const _firstNames = [
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
    'ANTONIO',
    'ISABEL',
    'FRANCISCO',
    'PATRICIA',
    'FERNANDO',
    'CARMEN',
    'RICARDO',
    'DIANA',
    'ANGELO',
    'JASMINE',
    'RAFAEL',
    'ANGELICA',
    'MARCO',
    'KRISTINE',
    'DANIEL',
    'NICOLE',
    'GABRIEL',
    'ANDREA',
    'ALEJANDRO',
    'CAMILLE',
    'JAMES',
    'BIANCA',
    'MARK',
    'JOYCE',
    'JULIUS',
    'RACHEL',
    'CHRISTIAN',
    'KATRINA',
    'KEVIN',
    'SAMANTHA',
    'AARON',
    'MICHELLE',
    'JOSHUA',
    'STEPHANIE',
    'NATHAN',
    'TRISHA',
    'KYLE',
    'MEGAN',
    'RYAN',
    'ALLISON',
    'JEROME',
    'CLAIRE',
    'LLOYD',
    'GRACE',
    'PAUL',
    'FAITH',
    'VINCENT',
    'HOPE',
    'BENEDICT',
    'JOY',
    'RENZ',
    'ALTHEA',
    'JARED',
    'CZARINA',
    'CARL',
    'JANELLE',
    'SEAN',
    'KYLA',
    'IAN',
    'CHERRY',
    'ALDRIN',
    'IVY',
    'LANCE',
    'DENISE',
    'PHILIP',
    'ARIEL',
    'BRYAN',
    'RINA',
    'TROY',
    'ELLA',
    'FRANCIS',
    'LIZA',
    'EMILIO',
    'YVONNE',
    'JAIME',
    'PRECIOUS',
    'EDWARD',
    'SHEILA',
    'ALVIN',
    'MARICEL',
    'RONALDO',
    'JENNELYN',
  ];

  static const _lastNames = [
    'DELA CRUZ',
    'SANTOS',
    'REYES',
    'GARCIA',
    'CRUZ',
    'BAUTISTA',
    'AQUINO',
    'FERNANDEZ',
    'RAMOS',
    'MENDOZA',
    'TORRES',
    'GONZALES',
    'LOPEZ',
    'CASTILLO',
    'RIVERA',
    'VILLANUEVA',
    'NAVARRO',
    'MARQUEZ',
    'SORIANO',
    'PASCUAL',
    'TOLENTINO',
    'AGUILAR',
    'SALAZAR',
    'HERRERA',
    'ROMERO',
    'MORALES',
    'DOMINGUEZ',
    'MERCADO',
    'SANTIAGO',
    'ENRIQUEZ',
    'MANALO',
    'PEREZ',
    'DIZON',
    'FLORES',
    'CONCEPCION',
    'OCAMPO',
    'ESPIRITU',
    'MAGNO',
    'ALFONSO',
    'LIM',
    'TAN',
    'CO',
    'SY',
    'UY',
    'CHUA',
    'ONG',
    'GO',
    'YU',
    'LEE',
    'CHAN',
    'PANGILINAN',
    'DIMACULANGAN',
    'MAGSAYSAY',
    'LACSON',
    'LIBUTAN',
    'PINEDA',
    'CABRERA',
    'SERRANO',
    'MIRANDA',
    'VELASCO',
  ];

  static const _middleNames = [
    'SANTOS',
    'REYES',
    'CRUZ',
    'BAUTISTA',
    'GARCIA',
    'LOPEZ',
    'RAMOS',
    'TORRES',
    'FERNANDEZ',
    'GONZALES',
    'MENDOZA',
    'RIVERA',
    'MORALES',
    'CASTILLO',
    'NAVARRO',
    'AGUILAR',
    'VILLANUEVA',
    'SORIANO',
    'PASCUAL',
    'HERRERA',
    'SALAZAR',
    'PEREZ',
    'FLORES',
    'ROMERO',
  ];

  static const _streets = [
    'RIZAL ST.',
    'MABINI ST.',
    'BONIFACIO AVE.',
    'AGUINALDO BLVD.',
    'QUEZON AVE.',
    'LAUREL ST.',
    'OSMENA BLVD.',
    'ROXAS BLVD.',
    'MAGALLANES ST.',
    'LUNA ST.',
    'DEL PILAR ST.',
    'JACINTO ST.',
    'SILANG ST.',
    'PLARIDEL ST.',
    'TANDANG SORA AVE.',
    'KATIPUNAN AVE.',
    'COMMONWEALTH AVE.',
    'AURORA BLVD.',
    'ESPAÑA BLVD.',
    'TAFT AVE.',
  ];

  static const _barangays = [
    'BRGY. SAN ANTONIO',
    'BRGY. POBLACION',
    'BRGY. BAGUMBAYAN',
    'BRGY. STA. CRUZ',
    'BRGY. SAN ISIDRO',
    'BRGY. MALANDAY',
    'BRGY. PINYAHAN',
    'BRGY. KRUS NA LIGAS',
    'BRGY. UP CAMPUS',
    'BRGY. LOYOLA HEIGHTS',
    'BRGY. TEACHERS VILLAGE',
    'BRGY. DILIMAN',
    'BRGY. COMMONWEALTH',
    'BRGY. BATASAN HILLS',
    'BRGY. HOLY SPIRIT',
  ];

  static const _cities = [
    'QUEZON CITY',
    'MANILA',
    'MAKATI',
    'PASIG',
    'TAGUIG',
    'CALOOCAN',
    'LAS PIÑAS',
    'PARAÑAQUE',
    'VALENZUELA',
    'MARIKINA',
    'SAN JUAN',
    'MANDALUYONG',
    'MUNTINLUPA',
    'PASAY',
    'MALABON',
  ];

  static String _pick(List<String> list) => list[_random.nextInt(list.length)];

  static const _extensions = ['', 'JR.', 'SR.', 'I', 'II', 'III'];

  static const _clinics = [
    'Pre-school Clinic',
    'Grade School Clinic',
    'Junior High School Clinic',
    'Senior High School Clinic',
    'College Clinic',
  ];

  static const _roles = ['Student', 'Employee'];

  static const _departments = [
    'Pre-school',
    'Grade School',
    'Junior High School',
    'Senior High School',
    'College',
  ];

  static const _treatments = [
    'Sent home',
    'Rested in clinic',
    'Given medication',
    'Wound cleaned and dressed',
    'Referred to hospital',
    'Observation',
  ];

  /// Supply definitions with name, type, and typical clinic assignments.
  static const _supplyDefinitions = [
    {'name': 'Alcohol', 'type': 'bottle'},
    {'name': 'Betadine', 'type': 'bottle'},
    {'name': 'Hydrogen Peroxide', 'type': 'bottle'},
    {'name': 'Cotton Balls', 'type': 'pack'},
    {'name': 'Bandage Roll', 'type': 'roll'},
    {'name': 'Gauze Pad', 'type': 'pack'},
    {'name': 'Adhesive Tape', 'type': 'roll'},
    {'name': 'Band-Aid', 'type': 'box'},
    {'name': 'Paracetamol', 'type': 'piece'},
    {'name': 'Mefenamic Acid', 'type': 'piece'},
    {'name': 'Ibuprofen', 'type': 'piece'},
    {'name': 'Thermometer', 'type': 'piece'},
    {'name': 'Ice Pack', 'type': 'piece'},
    {'name': 'Disposable Gloves', 'type': 'pair'},
    {'name': 'Face Mask', 'type': 'box'},
    {'name': 'First Aid Kit', 'type': 'set'},
  ];

  static Map<String, String> _generateNameComponents() {
    final first = _pick(_firstNames);
    final middle = _pick(_middleNames);
    final last = _pick(_lastNames);
    final ext = _random.nextDouble() < 0.1 ? _pick(_extensions) : '';

    final fullNameBuilder = StringBuffer('$last, $first $middle');
    if (ext.isNotEmpty) {
      fullNameBuilder.write(' $ext');
    }

    return {
      'firstName': first,
      'lastName': last,
      'middleName': middle,
      'extension': ext,
      'patientName': fullNameBuilder.toString(),
    };
  }

  static String _generateIdNumber(int index) {
    final year = 22 + _random.nextInt(3); // 22, 23, 24
    final suffixes = ['A', 'B', 'N', '']; // '' = no letter
    final suffix = _pick(suffixes);
    final seq = (_random.nextInt(9000) + 1000).toString(); // 1000–9999
    if (suffix.isEmpty) {
      return '$year-$seq';
    }
    return '$year$suffix-$seq';
  }

  static String _generateAddress() {
    final houseNum = _random.nextInt(999) + 1;
    return '$houseNum ${_pick(_streets)}, ${_pick(_barangays)}, ${_pick(_cities)}'
        .toUpperCase();
  }

  static String _generatePhone() {
    final prefix = [
      '0917',
      '0918',
      '0919',
      '0920',
      '0921',
      '0927',
      '0928',
      '0929',
      '0935',
      '0936',
      '0945',
      '0956',
      '0977',
      '0978',
      '0995',
      '0996',
      '0997',
    ];
    final num7 = _random.nextInt(9000000) + 1000000;
    return '${_pick(prefix)}$num7';
  }

  static DateTime _generateBirthdate() {
    // Ages between 4 and 25
    final age = 4 + _random.nextInt(22);
    final now = DateTime.now();
    return DateTime(
      now.year - age,
      1 + _random.nextInt(12),
      1 + _random.nextInt(28),
    );
  }

  static List<Patient> generate({int count = 500}) {
    final patients = <Patient>[];
    for (int i = 0; i < count; i++) {
      final createdAt = DateTime.now().subtract(
        Duration(days: _random.nextInt(365)),
      );
      final nameProvider = _generateNameComponents();
      final isMale = _random.nextBool();

      patients.add(
        Patient(
          id: _uuid.v4(),
          firstName: nameProvider['firstName'] ?? '',
          lastName: nameProvider['lastName'] ?? '',
          middleName: nameProvider['middleName'] ?? '',
          extension: nameProvider['extension'] ?? '',
          patientName: nameProvider['patientName'] ?? '',
          idNumber: _generateIdNumber(i),
          birthdate: _generateBirthdate(),
          sex: isMale ? 'Male' : 'Female',
          contactNumber: _generatePhone(),
          address: _generateAddress(),
          guardianName: _generateNameComponents()['patientName'] ?? '',
          guardianContact: _generatePhone(),
          role: _pick(_roles),
          department: _pick(_departments),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }
    return patients;
  }

  /// Generates inventory items across all clinics.
  static List<InventoryItem> _generateInventory() {
    final items = <InventoryItem>[];

    for (final clinic in _clinics) {
      // Each clinic gets a random subset of supplies
      final supplies = List.of(_supplyDefinitions)..shuffle(_random);
      final subsetCount = 8 + _random.nextInt(supplies.length - 8 + 1);

      for (int i = 0; i < subsetCount; i++) {
        final supply = supplies[i];
        final itemId = _uuid.v4();
        items.add(
          InventoryItem(
            id: itemId,
            itemName: supply['name']!,
            lowStockAmount: 3 + _random.nextInt(8), // 3–10
            clinic: clinic,
            itemType: supply['type']!,
            hlc: HLC.now('mock-node').toString(),
            nodeId: 'mock-node',
            stocks: [
              StockBatch(
                id: _uuid.v4(),
                itemId: itemId,
                amount: 5 + _random.nextInt(96),
                hlc: HLC.now('mock-node').toString(),
                nodeId: 'mock-node',
              ),
            ],
          ),
        );
      }
    }
    return items;
  }

  /// Inserts mock patients, inventory, and visitations into the database.
  /// Call this once from a debug button or startup check.
  static Future<void> seedDatabase({
    int count = 50,
    int visitationsPerPatient = 20,
  }) async {
    final db = DatabaseHelper.instance;
    final existing = await db.getPatients();
    if (existing.isNotEmpty) return; // Don't seed if data already exists

    // Seed inventory first so visitations can reference items
    final inventoryItems = _generateInventory();
    for (final item in inventoryItems) {
      await db.insertInventoryItem(item);
      for (final stock in item.stocks) {
        await db.insertStockBatch(stock);
      }
    }

    final patients = generate(count: count);
    for (final patient in patients) {
      final patientHlc = HLC.now('mock-node').toString();
      final pWithCrdt = patient.copyWith(hlc: patientHlc, nodeId: 'mock-node');
      await db.insertPatient(pWithCrdt);

      // Generate Visitations
      for (int j = 0; j < visitationsPerPatient; j++) {
        final visitDate = DateTime.now().subtract(
          Duration(days: _random.nextInt(365)),
        );

        // Pick 1–3 random symptoms
        final symptomCount = 1 + _random.nextInt(3);
        final shuffledSymptoms = List.of(kSymptomsList)..shuffle(_random);
        final symptoms = shuffledSymptoms.take(symptomCount).toList();

        // Pick 0–3 random supplies from inventory (in ID:Name format)
        final supplyCount = _random.nextInt(4); // 0–3
        final shuffledItems = List.of(inventoryItems)..shuffle(_random);
        final selectedItems = shuffledItems.take(supplyCount).toList();
        final suppliesUsed = selectedItems
            .map((i) => '${i.id}:${i.itemName}')
            .toList();

        // Determine consumed supplies (pieces are always consumed, others might be)
        final consumedSupplies = selectedItems
            .where((i) {
              if (i.itemType == 'piece') return true;
              return _random.nextDouble() < 0.2; // 20% chance of fully consumed
            })
            .map((i) => '${i.id}:${i.itemName}')
            .toList();

        // Pick 1–2 treatment strings
        final treatmentCount = 1 + _random.nextInt(2);
        final shuffledTreatments = List.of(_treatments)..shuffle(_random);
        final treatment = shuffledTreatments.take(treatmentCount).join(', ');

        final visit = Visitation(
          id: _uuid.v4(),
          patientId: patient.id,
          dateTime: visitDate,
          symptoms: symptoms,
          suppliesUsed: suppliesUsed,
          consumedSupplies: consumedSupplies,
          treatment: treatment,
          remarks: 'Mock data $j',
          hlc: HLC.now('mock-node').toString(),
          nodeId: 'mock-node',
        );
        await db.insertVisitation(visit);
      }
    }
  }
}
