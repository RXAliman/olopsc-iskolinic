import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
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
    'Rizal St.',
    'Mabini St.',
    'Bonifacio Ave.',
    'Aguinaldo Blvd.',
    'Quezon Ave.',
    'Laurel St.',
    'Osmena Blvd.',
    'Roxas Blvd.',
    'Magallanes St.',
    'Luna St.',
    'Del Pilar St.',
    'Jacinto St.',
    'Silang St.',
    'Plaridel St.',
    'Tandang Sora Ave.',
    'Katipunan Ave.',
    'Commonwealth Ave.',
    'Aurora Blvd.',
    'España Blvd.',
    'Taft Ave.',
  ];

  static const _barangays = [
    'Brgy. San Antonio',
    'Brgy. Poblacion',
    'Brgy. Bagumbayan',
    'Brgy. Sta. Cruz',
    'Brgy. San Isidro',
    'Brgy. Malanday',
    'Brgy. Pinyahan',
    'Brgy. Krus na Ligas',
    'Brgy. UP Campus',
    'Brgy. Loyola Heights',
    'Brgy. Teachers Village',
    'Brgy. Diliman',
    'Brgy. Commonwealth',
    'Brgy. Batasan Hills',
    'Brgy. Holy Spirit',
  ];

  static const _cities = [
    'Quezon City',
    'Manila',
    'Makati',
    'Pasig',
    'Taguig',
    'Caloocan',
    'Las Piñas',
    'Parañaque',
    'Valenzuela',
    'Marikina',
    'San Juan',
    'Mandaluyong',
    'Muntinlupa',
    'Pasay',
    'Malabon',
  ];

  static String _pick(List<String> list) => list[_random.nextInt(list.length)];

  static String _generateName() {
    final first = _pick(_firstNames);
    final middle = _pick(_middleNames);
    final last = _pick(_lastNames);
    // 30% chance to include middle initial
    if (_random.nextDouble() < 0.3) {
      return '$first ${middle[0]}. $last';
    }
    return '$first $last';
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
    return '$houseNum ${_pick(_streets)}, ${_pick(_barangays)}, ${_pick(_cities)}';
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

  static List<Patient> generate({int count = 500}) {
    final patients = <Patient>[];
    for (int i = 0; i < count; i++) {
      final createdAt = DateTime.now().subtract(
        Duration(days: _random.nextInt(365)),
      );
      patients.add(
        Patient(
          id: _uuid.v4(),
          patientName: _generateName(),
          idNumber: _generateIdNumber(i),
          address: _generateAddress(),
          guardianName: _generateName(),
          guardianContact: _generatePhone(),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }
    return patients;
  }

  /// Inserts 500 mock patients into the database.
  /// Call this once from a debug button or startup check.
  static Future<void> seedDatabase({int count = 500}) async {
    final db = DatabaseHelper.instance;
    final existing = await db.getPatients();
    if (existing.isNotEmpty) return; // Don't seed if data already exists

    final patients = generate(count: count);
    for (final patient in patients) {
      await db.insertPatient(patient);
    }
  }
}
