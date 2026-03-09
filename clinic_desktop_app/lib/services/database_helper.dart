import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../crdt/hlc.dart';

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
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'clinic.db');
    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        patientName TEXT NOT NULL,
        idNumber TEXT NOT NULL,
        address TEXT,
        guardianName TEXT,
        guardianContact TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        hlc TEXT NOT NULL DEFAULT '',
        nodeId TEXT NOT NULL DEFAULT '',
        isDeleted INTEGER NOT NULL DEFAULT 0
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
        hlc TEXT NOT NULL DEFAULT '',
        nodeId TEXT NOT NULL DEFAULT '',
        isDeleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (patientId) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    // Index on HLC for efficient sync queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_patients_hlc ON patients (hlc)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visitations_hlc ON visitations (hlc)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE visitations ADD COLUMN suppliesUsed TEXT');
      await db.execute('DROP TABLE IF EXISTS emergency_alerts');
    }
    if (oldVersion < 3) {
      // Add CRDT columns to patients
      await db.execute(
        "ALTER TABLE patients ADD COLUMN hlc TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE patients ADD COLUMN nodeId TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE patients ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0',
      );
      // Add CRDT columns to visitations
      await db.execute(
        "ALTER TABLE visitations ADD COLUMN hlc TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE visitations ADD COLUMN nodeId TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE visitations ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0',
      );
      // Create meta table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      // Indexes
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_patients_hlc ON patients (hlc)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visitations_hlc ON visitations (hlc)',
      );
    }
  }

  // ── Meta (key-value store) ──────────────────────────────────────

  Future<String?> getMeta(String key) async {
    final db = await database;
    final maps = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert('meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Patient CRUD (with soft-delete) ─────────────────────────────

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
    final maps = await db.query(
      'patients',
      where: 'isDeleted = 0',
      orderBy: 'patientName ASC',
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<List<Patient>> getPatientsPaginated(int limit, int offset) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'isDeleted = 0',
      orderBy: 'patientName ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<int> getPatientCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM patients WHERE isDeleted = 0',
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Patient>> searchPatientsPaginated(
    String query,
    int limit,
    int offset,
  ) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'isDeleted = 0 AND (patientName LIKE ? OR idNumber LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'patientName ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<int> searchPatientCount(String query) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM patients WHERE isDeleted = 0 AND (patientName LIKE ? OR idNumber LIKE ?)',
      ['%$query%', '%$query%'],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
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

  /// Soft-delete: marks the patient and its visitations as deleted.
  Future<void> deletePatient(String id, {required String hlc}) async {
    final db = await database;
    await db.update(
      'visitations',
      {'isDeleted': 1, 'hlc': hlc},
      where: 'patientId = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    await db.update(
      'patients',
      {'isDeleted': 1, 'hlc': hlc},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'isDeleted = 0 AND (patientName LIKE ? OR idNumber LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'patientName ASC',
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  // ── Visitation CRUD (with soft-delete) ──────────────────────────

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
      where: 'patientId = ? AND isDeleted = 0',
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
      where: 'isDeleted = 0 AND dateTime >= ? AND dateTime < ?',
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
      'SELECT COUNT(*) as count FROM visitations WHERE isDeleted = 0 AND dateTime >= ? AND dateTime < ?',
      [start, end],
    );
    return result.first['count'] as int? ?? 0;
  }

  // ── CRDT Sync Methods ──────────────────────────────────────────

  /// Get all patients changed since the given HLC (for outbound sync).
  Future<List<Patient>> getPatientChangesSince(String sinceHlc) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'hlc > ?',
      whereArgs: [sinceHlc],
      orderBy: 'hlc ASC',
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  /// Get all visitations changed since the given HLC (for outbound sync).
  Future<List<Visitation>> getVisitationChangesSince(String sinceHlc) async {
    final db = await database;
    final maps = await db.query(
      'visitations',
      where: 'hlc > ?',
      whereArgs: [sinceHlc],
      orderBy: 'hlc ASC',
    );
    return maps.map((m) => Visitation.fromMap(m)).toList();
  }

  /// CRDT merge: upsert a remote patient only if its HLC > local HLC.
  /// Returns true if a change was applied.
  Future<bool> upsertPatientFromRemote(Patient remote) async {
    final db = await database;
    final existing = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [remote.id],
    );

    if (existing.isEmpty) {
      await db.insert('patients', remote.toMap());
      return true;
    }

    final localHlc = HLC.unpack(existing.first['hlc'] as String? ?? '');
    final remoteHlc = HLC.unpack(remote.hlc);

    if (remoteHlc > localHlc) {
      await db.update(
        'patients',
        remote.toMap(),
        where: 'id = ?',
        whereArgs: [remote.id],
      );
      return true;
    }
    return false;
  }

  /// CRDT merge: upsert a remote visitation only if its HLC > local HLC.
  /// Returns true if a change was applied.
  Future<bool> upsertVisitationFromRemote(Visitation remote) async {
    final db = await database;
    final existing = await db.query(
      'visitations',
      where: 'id = ?',
      whereArgs: [remote.id],
    );

    if (existing.isEmpty) {
      await db.insert('visitations', remote.toMap());
      return true;
    }

    final localHlc = HLC.unpack(existing.first['hlc'] as String? ?? '');
    final remoteHlc = HLC.unpack(remote.hlc);

    if (remoteHlc > localHlc) {
      await db.update(
        'visitations',
        remote.toMap(),
        where: 'id = ?',
        whereArgs: [remote.id],
      );
      return true;
    }
    return false;
  }

  // ── Data Compaction ─────────────────────────────────────────────

  /// Permanently removes tombstoned records older than [daysThreshold] days.
  Future<int> compactTombstones({int daysThreshold = 90}) async {
    final db = await database;
    final cutoff = HLC(
      timestamp: DateTime.now()
          .subtract(Duration(days: daysThreshold))
          .millisecondsSinceEpoch,
      counter: 0,
      nodeId: '',
    ).pack();

    int removed = 0;
    removed += await db.delete(
      'visitations',
      where: 'isDeleted = 1 AND hlc < ?',
      whereArgs: [cutoff],
    );
    removed += await db.delete(
      'patients',
      where: 'isDeleted = 1 AND hlc < ?',
      whereArgs: [cutoff],
    );
    return removed;
  }
}
