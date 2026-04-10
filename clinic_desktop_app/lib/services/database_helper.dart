import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../models/inventory_item.dart';
import '../crdt/hlc.dart';
import 'package:uuid/uuid.dart';

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
        version: 11,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        middleName TEXT NOT NULL DEFAULT '',
        extension TEXT NOT NULL DEFAULT '',
        patientName TEXT NOT NULL,
        idNumber TEXT NOT NULL,
        birthdate TEXT,
        sex TEXT NOT NULL DEFAULT '',
        contactNumber TEXT NOT NULL DEFAULT '',
        address TEXT,
        guardianName TEXT,
        guardianContact TEXT,
        guardian2Name TEXT NOT NULL DEFAULT '',
        guardian2Contact TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        hlc TEXT NOT NULL DEFAULT '',
        nodeId TEXT NOT NULL DEFAULT '',
        isDeleted INTEGER NOT NULL DEFAULT 0,
        medicalHistory TEXT NOT NULL DEFAULT '[]',
        vaccinationHistory TEXT NOT NULL DEFAULT '[]',
        allergicTo TEXT NOT NULL DEFAULT '',
        patientRemarks TEXT NOT NULL DEFAULT '',
        permissions TEXT NOT NULL DEFAULT '{}'
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
    // Inventory table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id TEXT PRIMARY KEY,
        itemName TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        averageDailyUse INTEGER NOT NULL DEFAULT 0,
        leadTime INTEGER NOT NULL DEFAULT 0,
        safetyStock INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_name ON inventory (itemName)',
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
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_batches (
          id TEXT PRIMARY KEY,
          itemName TEXT NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 0,
          expirationDate TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_item ON stock_batches (itemName, expirationDate)',
      );
    }
    if (oldVersion < 5) {
      // Add the 4 new name fields to patients (safely wrap in try-catch in case they already exist)
      for (final col in ['firstName', 'lastName', 'middleName', 'extension']) {
        try {
          await db.execute("ALTER TABLE patients ADD COLUMN $col TEXT NOT NULL DEFAULT ''");
        } catch (_) {}
      }

      // Basic migration: move existing patientName to firstName to avoid empty required fields
      try {
        await db.execute("UPDATE patients SET firstName = patientName WHERE firstName = ''");
      } catch (_) {}
    }
    if (oldVersion < 6) {
      // Add the 5 new fields to patients
      await db.execute("ALTER TABLE patients ADD COLUMN birthdate TEXT");
      await db.execute("ALTER TABLE patients ADD COLUMN sex TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE patients ADD COLUMN contactNumber TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE patients ADD COLUMN guardian2Name TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE patients ADD COLUMN guardian2Contact TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 7) {
      // Add the 2 new JSON fields to patients
      await db.execute("ALTER TABLE patients ADD COLUMN medicalHistory TEXT NOT NULL DEFAULT '[]'");
      await db.execute("ALTER TABLE patients ADD COLUMN vaccinationHistory TEXT NOT NULL DEFAULT '[]'");
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN "allergic to" TEXT NOT NULL DEFAULT ""');
        await db.execute('ALTER TABLE patients ADD COLUMN "patient remarks" TEXT NOT NULL DEFAULT ""');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE patients ADD COLUMN allergicTo TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE patients ADD COLUMN patientRemarks TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 10) {
      await db.execute("ALTER TABLE patients ADD COLUMN permissions TEXT NOT NULL DEFAULT '{}'");
    }
    if (oldVersion < 11) {
      // Create new inventory table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory (
          id TEXT PRIMARY KEY,
          itemName TEXT NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 0,
          averageDailyUse INTEGER NOT NULL DEFAULT 0,
          leadTime INTEGER NOT NULL DEFAULT 0,
          safetyStock INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');

      // Migrate data from stock_batches if it exists
      try {
        final List<Map<String, dynamic>> batchMaps = await db.query('stock_batches');
        if (batchMaps.isNotEmpty) {
          final summary = <String, int>{};
          for (final row in batchMaps) {
            final name = row['itemName'] as String;
            final qty = row['quantity'] as int;
            summary[name] = (summary[name] ?? 0) + qty;
          }

          for (final entry in summary.entries) {
            await db.insert('inventory', {
              'id': const Uuid().v4(),
              'itemName': entry.key,
              'quantity': entry.value,
              'averageDailyUse': 0,
              'leadTime': 0,
              'safetyStock': 0,
              'createdAt': DateTime.now().toIso8601String(),
            });
          }
        }
        await db.execute('DROP TABLE IF EXISTS stock_batches');
      } catch (e) {
        // Table might not exist or migration failed, continue
      }
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
      where:
          'isDeleted = 0 AND (patientName LIKE ? OR idNumber LIKE ? OR firstName LIKE ? OR lastName LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'patientName ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<int> searchPatientCount(String query) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM patients WHERE isDeleted = 0 AND (patientName LIKE ? OR idNumber LIKE ? OR firstName LIKE ? OR lastName LIKE ?)',
      ['%$query%', '%$query%', '%$query%', '%$query%'],
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

  Future<Patient?> getPatientByIdNumber(String idNumber) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'isDeleted = 0 AND idNumber = ?',
      whereArgs: [idNumber],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
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

  Future<void> updateVisitation(Visitation visit) async {
    final db = await database;
    await db.update(
      'visitations',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
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

  Future<List<Visitation>> getVisitationsPaginated(
    String patientId,
    int limit,
    int offset,
  ) async {
    final db = await database;
    final maps = await db.query(
      'visitations',
      where: 'patientId = ? AND isDeleted = 0',
      whereArgs: [patientId],
      orderBy: 'dateTime DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Visitation.fromMap(m)).toList();
  }

  Future<int> getVisitationCountForPatient(String patientId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM visitations WHERE patientId = ? AND isDeleted = 0',
      [patientId],
    );
    return result.first['count'] as int? ?? 0;
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

  /// Gets today's visitations along with the patient's name, paginated.
  Future<List<Map<String, dynamic>>> getTodayVisitationsPaginated(int limit, int offset) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    
    final maps = await db.rawQuery(
      '''
      SELECT v.*, p.patientName, p.firstName 
      FROM visitations v 
      JOIN patients p ON v.patientId = p.id 
      WHERE v.isDeleted = 0 
        AND v.dateTime >= ? 
        AND v.dateTime < ?
      ORDER BY v.dateTime DESC
      LIMIT ? OFFSET ?
      ''',
      [start, end, limit, offset],
    );
    
    return maps;
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

  Future<bool> upsertVisitationFromRemote(Visitation remote) async {
    final db = await database;
    try {
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
    } catch (e) {
      if (e is DatabaseException &&
          e.isUniqueConstraintError() == false &&
          e.toString().contains('FOREIGN KEY')) {
        // Orphaned visitation (synced before its parent patient record arrived).
        // Since we chunk patients first, this is rare, but if it happens, we
        // skip inserting to prevent the isolate from crashing. The sync protocol
        // will naturally resolve this if we eventually get the patient record.
        return false;
      }
      rethrow;
    }
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

  // ── Inventory (New Tabular Model) ─────────────────────────────

  Future<void> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert(
      'inventory',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InventoryItem>> getAllInventory() async {
    final db = await database;
    final maps = await db.query('inventory', orderBy: 'itemName ASC');
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<void> deleteInventoryItem(String id) async {
    final db = await database;
    await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.update(
      'inventory',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deductStock(String itemName, int qty) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'inventory',
      where: 'itemName = ?',
      whereArgs: [itemName],
    );

    if (results.isEmpty) return 0;

    final currentQty = results.first['quantity'] as int;
    final newQty = currentQty - qty;

    await db.update(
      'inventory',
      {'quantity': newQty},
      where: 'itemName = ?',
      whereArgs: [itemName],
    );

    return qty;
  }

  Future<void> addStock(String itemName, int qty) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'inventory',
      where: 'itemName = ?',
      whereArgs: [itemName],
    );

    if (results.isEmpty) return;

    final currentQty = results.first['quantity'] as int;
    final newQty = currentQty + qty;

    await db.update(
      'inventory',
      {'quantity': newQty},
      where: 'itemName = ?',
      whereArgs: [itemName],
    );
  }

  // TODO: Delete this after testing
  /// Clears all tables in the database.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('visitations');
      await txn.delete('patients');
      await txn.delete('inventory');
      await txn.delete('meta');
    });
  }

  /// Close the database connection gracefully.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
