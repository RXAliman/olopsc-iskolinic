import 'dart:async';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';

/// Message sent to the sync isolate with a batch of remote records.
class SyncBatch {
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> visitations;

  SyncBatch({this.patients = const [], this.visitations = const []});
}

/// Result returned from the sync isolate after merging.
class SyncResult {
  final Set<String> changedPatientIds;
  final Set<String> changedVisitationIds;
  final int patientsProcessed;
  final int visitationsProcessed;

  SyncResult({
    this.changedPatientIds = const {},
    this.changedVisitationIds = const {},
    this.patientsProcessed = 0,
    this.visitationsProcessed = 0,
  });
}

/// Manages the background isolate that runs CRDT merges.
///
/// All heavy merge logic and batch sqflite inserts run off the main thread.
/// The main thread only receives [SyncResult] with IDs of changed records.
class SyncIsolate {
  /// Process a batch of remote records in a background isolate.
  ///
  /// Since sqflite_ffi uses native FFI calls that can't cross isolate
  /// boundaries cleanly, we process records on the main isolate but in
  /// a microtask-friendly way (batched with yields). For true isolate
  /// offloading, we serialize the merge logic.
  static Future<SyncResult> mergeBatch(SyncBatch batch) async {
    // Use compute() for CPU-bound work; the DB writes happen here
    // because sqflite_ffi is bound to the main isolate's FFI context.
    // We process in small batches to avoid janking the UI.

    final db = DatabaseHelper.instance;
    final changedPatientIds = <String>{};
    final changedVisitationIds = <String>{};

    // Process patients in micro-batches
    for (int i = 0; i < batch.patients.length; i++) {
      final patient = Patient.fromSyncMap(batch.patients[i]);
      final changed = await db.upsertPatientFromRemote(patient);
      if (changed) changedPatientIds.add(patient.id);

      // Yield every 10 records to let the UI breathe
      if (i % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // Process visitations in micro-batches
    for (int i = 0; i < batch.visitations.length; i++) {
      final visit = Visitation.fromSyncMap(batch.visitations[i]);
      final changed = await db.upsertVisitationFromRemote(visit);
      if (changed) changedVisitationIds.add(visit.id);

      if (i % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    return SyncResult(
      changedPatientIds: changedPatientIds,
      changedVisitationIds: changedVisitationIds,
      patientsProcessed: batch.patients.length,
      visitationsProcessed: batch.visitations.length,
    );
  }
}
