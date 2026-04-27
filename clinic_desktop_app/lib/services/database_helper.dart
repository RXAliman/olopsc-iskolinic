import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../models/inventory_item.dart';
import '../models/custom_symptom.dart';
import '../crdt/hlc.dart';
import '../constants/app_config.dart';

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
    final dbPath = p.join(dir.path, AppConfig.databaseName);
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
        permissions TEXT NOT NULL DEFAULT '{}',
        role TEXT NOT NULL DEFAULT '',
        department TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE visitations (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        symptoms TEXT,
        suppliesUsed TEXT,
        consumedSupplies TEXT NOT NULL DEFAULT '',
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
        lowStockAmount INTEGER NOT NULL DEFAULT 0,
        clinic TEXT NOT NULL DEFAULT '',
        itemType TEXT NOT NULL DEFAULT 'piece',
        createdAt TEXT NOT NULL,
        hlc TEXT NOT NULL DEFAULT '',
        nodeId TEXT NOT NULL DEFAULT '',
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_name ON inventory (itemName)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_hlc ON inventory (hlc)',
    );
    // Custom Symptoms table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_symptoms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        hlc TEXT NOT NULL DEFAULT '',
        nodeId TEXT NOT NULL DEFAULT '',
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_custom_symptoms_hlc ON custom_symptoms (hlc)',
    );
    // Inventory Stocks table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_stocks (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        amount INTEGER NOT NULL DEFAULT 0,
        expiryDate TEXT,
        createdAt TEXT NOT NULL,
        hlc TEXT NOT NULL DEFAULT '',
        nodeId TEXT NOT NULL DEFAULT '',
        isDeleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (itemId) REFERENCES inventory (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_stocks_itemId ON inventory_stocks (itemId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_stocks_expiry ON inventory_stocks (expiryDate)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_stocks_hlc ON inventory_stocks (hlc)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate inventory clinic names to the new terminology
      await db.execute(
        "UPDATE inventory SET clinic = 'Clinic A' "
        "WHERE clinic IN ('Pre-school Clinic', 'Junior High School Clinic', 'Senior High School Clinic', 'College Clinic')",
      );
      await db.execute(
        "UPDATE inventory SET clinic = 'Clinic B' "
        "WHERE clinic = 'Grade School Clinic'",
      );
    }
    if (oldVersion < 3) {
      // 1. Create inventory_stocks table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_stocks (
          id TEXT PRIMARY KEY,
          itemId TEXT NOT NULL,
          amount INTEGER NOT NULL DEFAULT 0,
          expiryDate TEXT,
          createdAt TEXT NOT NULL,
          hlc TEXT NOT NULL DEFAULT '',
          nodeId TEXT NOT NULL DEFAULT '',
          isDeleted INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (itemId) REFERENCES inventory (id)
        )
      ''');

      // 2. Migrate existing inventory to stocks
      // We group by itemName + clinic to keep them separate per clinic as requested
      final List<Map<String, dynamic>> items = await db.query('inventory');

      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final item in items) {
        final key = "${item['itemName']}_${item['clinic']}";
        groups.putIfAbsent(key, () => []).add(item);
      }

      final now = DateTime.now().toIso8601String();

      for (final group in groups.values) {
        // The first item in the group is our survivor
        final survivor = group.first;
        final survivorId = survivor['id'] as String;

        // 2a. Create a separate stock batch for EACH item in the group
        for (final item in group) {
          final qty = item['quantity'] as int? ?? 0;
          if (qty > 0) {
            await db.insert('inventory_stocks', {
              'id': 'legacy_${item['id']}',
              'itemId': survivorId,
              'amount': qty,
              'expiryDate': null,
              'createdAt': now,
              'hlc': item['hlc'],
              'nodeId': item['nodeId'],
              'isDeleted': 0,
            });
          }
        }

        // 2b. Delete all other items in the group from the inventory table
        for (int i = 1; i < group.length; i++) {
          await db.delete(
            'inventory',
            where: 'id = ?',
            whereArgs: [group[i]['id']],
          );
        }
      }

      // 3. Add indices for the new table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_inventory_stocks_itemId ON inventory_stocks (itemId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_inventory_stocks_expiry ON inventory_stocks (expiryDate)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_inventory_stocks_hlc ON inventory_stocks (hlc)',
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

  Future<Visitation?> getVisitation(String id) async {
    final db = await database;
    final maps = await db.query(
      'visitations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Visitation.fromMap(maps.first);
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
  Future<List<Map<String, dynamic>>> getTodayVisitationsPaginated(
    int limit,
    int offset,
  ) async {
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
    final itemMaps = await db.query(
      'inventory',
      where: 'isDeleted = 0',
      orderBy: 'itemName ASC',
    );

    final List<InventoryItem> items = [];
    for (final itemMap in itemMaps) {
      final itemId = itemMap['id'] as String;
      final stockMaps = await db.query(
        'inventory_stocks',
        where: 'itemId = ? AND isDeleted = 0',
        whereArgs: [itemId],
      );
      final stocks = stockMaps.map((m) => StockBatch.fromMap(m)).toList();
      items.add(InventoryItem.fromMap(itemMap, stocks: stocks));
    }
    return items;
  }

  Future<int> getInventoryCount(String query) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM inventory WHERE isDeleted = 0 AND itemName LIKE ?',
      ['%$query%'],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<List<InventoryItem>> searchInventoryPaginated({
    required String query,
    required int limit,
    required int offset,
    required String orderBy,
    required bool ascending,
  }) async {
    final db = await database;
    final itemMaps = await db.query(
      'inventory',
      where: 'isDeleted = 0 AND itemName LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: '$orderBy ${ascending ? 'ASC' : 'DESC'}',
      limit: limit,
      offset: offset,
    );

    final List<InventoryItem> items = [];
    for (final itemMap in itemMaps) {
      final itemId = itemMap['id'] as String;
      final stockMaps = await db.query(
        'inventory_stocks',
        where: 'itemId = ? AND isDeleted = 0',
        whereArgs: [itemId],
      );
      final stocks = stockMaps.map((m) => StockBatch.fromMap(m)).toList();
      items.add(InventoryItem.fromMap(itemMap, stocks: stocks));
    }
    return items;
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await database;
    final itemMaps = await db.query(
      'inventory',
      where: 'isDeleted = 0',
      orderBy: 'itemName ASC',
    );

    final List<InventoryItem> items = [];
    for (final itemMap in itemMaps) {
      final itemId = itemMap['id'] as String;
      final stockMaps = await db.query(
        'inventory_stocks',
        where: 'itemId = ? AND isDeleted = 0',
        whereArgs: [itemId],
      );
      final stocks = stockMaps.map((m) => StockBatch.fromMap(m)).toList();
      items.add(InventoryItem.fromMap(itemMap, stocks: stocks));
    }
    return items;
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final allItems = await getAllInventoryItems();
    return allItems.where((item) => item.isLowStock).toList();
  }

  Future<void> deleteInventoryItemSoft(
    String id, {
    required String hlc,
    required String nodeId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'inventory',
        {'isDeleted': 1, 'hlc': hlc, 'nodeId': nodeId},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'inventory_stocks',
        {'isDeleted': 1, 'hlc': hlc, 'nodeId': nodeId},
        where: 'itemId = ?',
        whereArgs: [id],
      );
    });
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

  // ── Inventory Stock CRUD ────────────────────────────────────────

  Future<void> insertStockBatch(StockBatch batch) async {
    final db = await database;
    await db.insert(
      'inventory_stocks',
      batch.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStockBatch(StockBatch batch) async {
    final db = await database;
    await db.update(
      'inventory_stocks',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> deleteStockBatch(
    String id, {
    required String hlc,
    required String nodeId,
  }) async {
    final db = await database;
    await db.update(
      'inventory_stocks',
      {'isDeleted': 1, 'hlc': hlc, 'nodeId': nodeId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deductStock(
    String itemId,
    int qty, {
    required String hlc,
    required String nodeId,
  }) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      // Fetch active batches, ordered by expiry date (null expiry at the end)
      final List<Map<String, dynamic>> stockMaps = await txn.query(
        'inventory_stocks',
        where: 'itemId = ? AND isDeleted = 0 AND amount > 0',
        whereArgs: [itemId],
        orderBy: 'expiryDate ASC, createdAt ASC',
      );

      if (stockMaps.isEmpty) return 0;

      int remainingToDeduct = qty;
      for (final map in stockMaps) {
        if (remainingToDeduct <= 0) break;

        final batchId = map['id'] as String;
        final currentAmount = map['amount'] as int;

        if (currentAmount <= remainingToDeduct) {
          // Consume whole batch — soft-delete it
          remainingToDeduct -= currentAmount;
          await txn.update(
            'inventory_stocks',
            {'amount': 0, 'isDeleted': 1, 'hlc': hlc, 'nodeId': nodeId},
            where: 'id = ?',
            whereArgs: [batchId],
          );
        } else {
          // Partially consume batch
          final newAmount = currentAmount - remainingToDeduct;
          remainingToDeduct = 0;
          await txn.update(
            'inventory_stocks',
            {'amount': newAmount, 'hlc': hlc, 'nodeId': nodeId},
            where: 'id = ?',
            whereArgs: [batchId],
          );
        }
      }

      // Return the actual amount deducted
      return qty - remainingToDeduct;
    });
  }

  // addStock is no longer needed in this form because we use insertStockBatch
  // to add new specific batches with expiries.

  Future<void> purgeOldRecords(int years) async {
    final db = await database;
    final thresholdDate = DateTime.now().subtract(Duration(days: years * 365));
    final thresholdIso = thresholdDate.toIso8601String();

    // Get node HLC to mark soft delete
    final nodeIdStr = await getMeta('nodeId') ?? 'unknown';
    final hlcStr = HLC.now(nodeIdStr).pack();

    await db.transaction((txn) async {
      // Find old patients
      final oldPatients = await txn.query(
        'patients',
        columns: ['id'],
        where: 'createdAt < ? AND isDeleted = 0',
        whereArgs: [thresholdIso],
      );

      for (final p in oldPatients) {
        final pid = p['id'] as String;
        // Mark patient deleted
        await txn.update(
          'patients',
          {'isDeleted': 1, 'hlc': hlcStr, 'nodeId': nodeIdStr},
          where: 'id = ?',
          whereArgs: [pid],
        );
        // Mark associated visitations deleted
        await txn.update(
          'visitations',
          {'isDeleted': 1, 'hlc': hlcStr, 'nodeId': nodeIdStr},
          where: 'patientId = ?',
          whereArgs: [pid],
        );
      }
    });
  }

  /// Count active patient records older than [years] years.
  Future<int> countOldRecords(int years) async {
    final db = await database;
    final thresholdDate = DateTime.now().subtract(Duration(days: years * 365));
    final thresholdIso = thresholdDate.toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM patients WHERE createdAt < ? AND isDeleted = 0',
      [thresholdIso],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> garbageCollectTombstones() async {
    final db = await database;
    // 30 days in milliseconds
    final cutoffTimestamp =
        DateTime.now().millisecondsSinceEpoch - (30 * 24 * 60 * 60 * 1000);

    await db.transaction((txn) async {
      final tables = [
        'patients',
        'visitations',
        'inventory',
        'custom_symptoms',
      ];
      for (final table in tables) {
        final deletedRecords = await txn.query(
          table,
          columns: ['id', 'hlc'],
          where: 'isDeleted = 1',
        );
        for (final r in deletedRecords) {
          final id = r['id'] as String;
          final hlc = r['hlc'] as String;
          try {
            final unpacked = HLC.unpack(hlc);
            // Verify timestamp is older than 30 days and valid (>0)
            if (unpacked.timestamp > 0 &&
                unpacked.timestamp < cutoffTimestamp) {
              await txn.delete(table, where: 'id = ?', whereArgs: [id]);
            }
          } catch (e) {
            // skip if malformed
          }
        }
      }
    });
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

  // ── Custom Symptoms ───────────────────────────────────────────────

  Future<int> insertCustomSymptom(CustomSymptom symptom) async {
    final db = await database;
    return await db.insert('custom_symptoms', symptom.toMap());
  }

  Future<List<CustomSymptom>> getCustomSymptomsByCategory(
    String category,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_symptoms',
      where: 'category = ? AND isDeleted = 0',
      whereArgs: [category],
    );
    return maps.map((m) => CustomSymptom.fromMap(m)).toList();
  }

  Future<List<CustomSymptom>> getAllCustomSymptoms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_symptoms',
      where: 'isDeleted = 0',
    );
    return maps.map((m) => CustomSymptom.fromMap(m)).toList();
  }

  Future<List<CustomSymptom>> getCustomSymptomChangesSince(
    String sinceHlc,
  ) async {
    final db = await database;
    final maps = await db.query(
      'custom_symptoms',
      where: 'hlc > ?',
      whereArgs: [sinceHlc],
      orderBy: 'hlc ASC',
    );
    return maps.map((m) => CustomSymptom.fromMap(m)).toList();
  }

  Future<bool> upsertCustomSymptomFromRemote(CustomSymptom remote) async {
    final db = await database;
    final existing = await db.query(
      'custom_symptoms',
      where: 'id = ?',
      whereArgs: [remote.id],
    );

    if (existing.isEmpty) {
      await db.insert('custom_symptoms', remote.toMap());
      return true;
    }

    final localHlc = HLC.unpack(existing.first['hlc'] as String? ?? '');
    final remoteHlc = HLC.unpack(remote.hlc);

    if (remoteHlc > localHlc) {
      await db.update(
        'custom_symptoms',
        remote.toMap(),
        where: 'id = ?',
        whereArgs: [remote.id],
      );
      return true;
    }
    return false;
  }

  // ── Inventory CRDT ──────────────────────────────────────────────

  Future<List<InventoryItem>> getInventoryChangesSince(String sinceHlc) async {
    final db = await database;
    final maps = await db.query(
      'inventory',
      where: 'hlc > ?',
      whereArgs: [sinceHlc],
      orderBy: 'hlc ASC',
    );
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<bool> upsertInventoryFromRemote(InventoryItem remote) async {
    final db = await database;
    final existing = await db.query(
      'inventory',
      where: 'id = ?',
      whereArgs: [remote.id],
    );

    if (existing.isEmpty) {
      await db.insert('inventory', remote.toMap());
      return true;
    }

    final localHlc = HLC.unpack(existing.first['hlc'] as String? ?? '');
    final remoteHlc = HLC.unpack(remote.hlc);

    if (remoteHlc > localHlc) {
      await db.update(
        'inventory',
        remote.toMap(),
        where: 'id = ?',
        whereArgs: [remote.id],
      );
      return true;
    }
    return false;
  }

  // ── Inventory Stocks CRDT ──────────────────────────────────────

  Future<List<StockBatch>> getInventoryStockChangesSince(
    String sinceHlc,
  ) async {
    final db = await database;
    final maps = await db.query(
      'inventory_stocks',
      where: 'hlc > ?',
      whereArgs: [sinceHlc],
      orderBy: 'hlc ASC',
    );
    return maps.map((m) => StockBatch.fromMap(m)).toList();
  }

  Future<bool> upsertInventoryStockFromRemote(StockBatch remote) async {
    final db = await database;
    final existing = await db.query(
      'inventory_stocks',
      where: 'id = ?',
      whereArgs: [remote.id],
    );

    if (existing.isEmpty) {
      await db.insert('inventory_stocks', remote.toMap());
      return true;
    }

    final localHlc = HLC.unpack(existing.first['hlc'] as String? ?? '');
    final remoteHlc = HLC.unpack(remote.hlc);

    if (remoteHlc > localHlc) {
      await db.update(
        'inventory_stocks',
        remote.toMap(),
        where: 'id = ?',
        whereArgs: [remote.id],
      );
      return true;
    }
    return false;
  }

  /// Close the database connection gracefully.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
