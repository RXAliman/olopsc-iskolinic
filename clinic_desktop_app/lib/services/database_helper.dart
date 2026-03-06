import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/patient.dart';
import '../models/visitation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'clinic_app', 'clinic.db');
    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        studentName TEXT NOT NULL,
        studentNumber TEXT NOT NULL,
        address TEXT,
        guardianName TEXT,
        guardianContact TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE visitations (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        symptoms TEXT,
        suppliesUsed TEXT,
        treatment TEXT,
        remarks TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add suppliesUsed column to visitations
      await db.execute('ALTER TABLE visitations ADD COLUMN suppliesUsed TEXT');
      // Drop emergency_alerts table if it exists
      await db.execute('DROP TABLE IF EXISTS emergency_alerts');
    }
  }

  // ── Patient CRUD ──────────────────────────────────────────────

  Future<void> insertPatient(Patient patient) async {
    final db = await database;
    await db.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Patient>> getPatients() async {
    final db = await database;
    final maps = await db.query('patients', orderBy: 'studentName ASC');
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<void> updatePatient(Patient patient) async {
    final db = await database;
    await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('visitations', where: 'patientId = ?', whereArgs: [id]);
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'studentName LIKE ? OR studentNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'studentName ASC',
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  // ── Visitation CRUD ───────────────────────────────────────────

  Future<void> insertVisitation(Visitation visit) async {
    final db = await database;
    await db.insert(
      'visitations',
      visit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Visitation>> getVisitationsForPatient(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'visitations',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'dateTime DESC',
    );
    return maps.map((m) => Visitation.fromMap(m)).toList();
  }

  Future<List<Visitation>> getVisitationsForMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'visitations',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [start, end],
    );
    return maps.map((m) => Visitation.fromMap(m)).toList();
  }

  Future<int> getTodayVisitCount() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM visitations WHERE dateTime >= ? AND dateTime < ?',
      [start, end],
    );
    return result.first['count'] as int? ?? 0;
  }
}
