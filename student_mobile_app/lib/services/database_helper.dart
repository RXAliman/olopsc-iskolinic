import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/student_user.dart';
import '../models/medical_record.dart';
import '../models/visitation.dart';
import '../models/emergency_alert.dart';

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
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'student_app', 'student.db');
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE student_users (
        id TEXT PRIMARY KEY,
        studentName TEXT NOT NULL,
        studentNumber TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        guardianName TEXT,
        guardianEmail TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medical_records (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        filePath TEXT,
        uploadedAt TEXT NOT NULL,
        parentAcknowledged INTEGER DEFAULT 0,
        parentNotes TEXT,
        FOREIGN KEY (studentId) REFERENCES student_users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE visitations (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        symptoms TEXT,
        treatment TEXT,
        remarks TEXT,
        followUpDate TEXT,
        followUpCompleted INTEGER DEFAULT 0,
        followUpNotes TEXT,
        FOREIGN KEY (studentId) REFERENCES student_users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE emergency_alerts (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        studentNumber TEXT NOT NULL,
        message TEXT,
        location TEXT,
        timestamp TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (studentId) REFERENCES student_users (id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Student User CRUD ──────────────────────────────────────────

  Future<void> insertUser(StudentUser user) async {
    final db = await database;
    await db.insert(
      'student_users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StudentUser?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'student_users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return StudentUser.fromMap(maps.first);
  }

  Future<StudentUser?> getUser(String id) async {
    final db = await database;
    final maps = await db.query(
      'student_users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StudentUser.fromMap(maps.first);
  }

  Future<void> updateUser(StudentUser user) async {
    final db = await database;
    await db.update(
      'student_users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ── Medical Records CRUD ───────────────────────────────────────

  Future<void> insertMedicalRecord(MedicalRecord record) async {
    final db = await database;
    await db.insert(
      'medical_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MedicalRecord>> getMedicalRecords(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'medical_records',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'uploadedAt DESC',
    );
    return maps.map((m) => MedicalRecord.fromMap(m)).toList();
  }

  Future<void> updateMedicalRecord(MedicalRecord record) async {
    final db = await database;
    await db.update(
      'medical_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteMedicalRecord(String id) async {
    final db = await database;
    await db.delete('medical_records', where: 'id = ?', whereArgs: [id]);
  }

  // ── Visitation CRUD ────────────────────────────────────────────

  Future<void> insertVisitation(Visitation visit) async {
    final db = await database;
    await db.insert(
      'visitations',
      visit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Visitation>> getVisitations(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'visitations',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'dateTime DESC',
    );
    return maps.map((m) => Visitation.fromMap(m)).toList();
  }

  Future<void> updateVisitation(Visitation visit) async {
    final db = await database;
    await db.update(
      'visitations',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> getPendingFollowUpCount(String studentId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM visitations WHERE studentId = ? AND followUpDate IS NOT NULL AND followUpCompleted = 0',
      [studentId],
    );
    return result.first['count'] as int? ?? 0;
  }

  // ── Emergency Alerts CRUD ──────────────────────────────────────

  Future<void> insertEmergencyAlert(EmergencyAlert alert) async {
    final db = await database;
    await db.insert(
      'emergency_alerts',
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EmergencyAlert>> getEmergencyAlerts(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'emergency_alerts',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => EmergencyAlert.fromMap(m)).toList();
  }

  Future<void> updateAlertStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'emergency_alerts',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
