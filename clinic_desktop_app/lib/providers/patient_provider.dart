import 'dart:async';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';
import '../crdt/hlc.dart';
import '../crdt/node_id.dart';
import 'package:uuid/uuid.dart';

class PatientProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Reference to SyncProvider for auto-push after writes.
  /// Set via [setOnLocalWrite] after both providers are created.
  VoidCallback? _onLocalWrite;

  /// Debounce timer — collapses rapid writes into a single push.
  Timer? _pushDebounce;
  static const _pushDebounceDelay = Duration(milliseconds: 200);

  // Current HLC state (loaded once on init)
  HLC _clock = const HLC(timestamp: 0, counter: 0, nodeId: '');
  String _nodeId = '';

  // Paginated patient data
  List<Patient> _patients = [];
  int _totalPatients = 0;
  int _currentPage = 0;
  final int _pageSize = 10;
  String _searchQuery = '';
  bool _loading = false;

  // Selected patient & visitations
  List<Visitation> _visitations = [];
  Patient? _selectedPatient;

  // IDs of records changed by the last sync (for granular rebuild)
  Set<String> _lastSyncChangedIds = {};

  List<Patient> get patients => _patients;
  int get totalPatients => _totalPatients;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalPatients / _pageSize).ceil();
  Patient? get selectedPatient => _selectedPatient;
  List<Visitation> get visitations => _visitations;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  Set<String> get lastSyncChangedIds => _lastSyncChangedIds;

  /// Register a callback that fires after every local write (used for auto-push sync).
  void setOnLocalWrite(VoidCallback callback) {
    _onLocalWrite = callback;
  }

  /// Initialize CRDT state — call once on startup.
  Future<void> initCrdt() async {
    _nodeId = await NodeId.get();
    _clock = HLC.now(_nodeId);
  }

  /// Advance the clock for a local write and return the packed HLC string.
  String _tick() {
    _clock = _clock.send();
    return _clock.pack();
  }

  /// Debounced push — waits 200ms after the last write before pushing.
  /// This collapses rapid writes (e.g. bulk imports) into a single sync push.
  void _autoPush() {
    _pushDebounce?.cancel();
    _pushDebounce = Timer(_pushDebounceDelay, () {
      _onLocalWrite?.call();
    });
  }

  Future<void> loadPatients() async {
    _loading = true;
    notifyListeners();

    final offset = _currentPage * _pageSize;

    if (_searchQuery.isEmpty) {
      _totalPatients = await _db.getPatientCount();
      _patients = await _db.getPatientsPaginated(_pageSize, offset);
    } else {
      _totalPatients = await _db.searchPatientCount(_searchQuery);
      _patients = await _db.searchPatientsPaginated(
        _searchQuery,
        _pageSize,
        offset,
      );
    }

    _loading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 0;
    loadPatients();
  }

  void goToPage(int page) {
    if (page < 0 || page >= totalPages) return;
    _currentPage = page;
    loadPatients();
  }

  void nextPage() => goToPage(_currentPage + 1);
  void previousPage() => goToPage(_currentPage - 1);
  void firstPage() => goToPage(0);
  void lastPage() => goToPage(totalPages - 1);

  Future<void> addPatient(Patient patient) async {
    final hlc = _tick();
    final withCrdt = Patient(
      id: patient.id,
      patientName: patient.patientName,
      idNumber: patient.idNumber,
      address: patient.address,
      guardianName: patient.guardianName,
      guardianContact: patient.guardianContact,
      createdAt: patient.createdAt,
      updatedAt: patient.updatedAt,
      hlc: hlc,
      nodeId: _nodeId,
    );
    await _db.insertPatient(withCrdt);
    await loadPatients();
    _autoPush();
  }

  Future<void> updatePatient(Patient patient) async {
    final hlc = _tick();
    final withCrdt = patient.copyWith(hlc: hlc, nodeId: _nodeId);
    await _db.updatePatient(withCrdt);
    await loadPatients();
    if (_selectedPatient?.id == patient.id) {
      _selectedPatient = withCrdt;
      notifyListeners();
    }
    _autoPush();
  }

  /// Soft-delete: sets isDeleted = 1 with a new HLC.
  Future<void> deletePatient(String id) async {
    final hlc = _tick();
    await _db.deletePatient(id, hlc: hlc);
    if (_selectedPatient?.id == id) {
      _selectedPatient = null;
      _visitations = [];
    }
    // Clamp page if we deleted the last item on the last page
    final newTotal = await _db.getPatientCount();
    final newTotalPages = (newTotal / _pageSize).ceil();
    if (_currentPage >= newTotalPages && _currentPage > 0) {
      _currentPage = newTotalPages - 1;
    }
    await loadPatients();
    _autoPush();
  }

  Future<void> selectPatient(Patient patient) async {
    _selectedPatient = patient;
    _visitations = await _db.getVisitationsForPatient(patient.id);
    notifyListeners();
  }

  Future<void> addVisitation({
    required String patientId,
    required List<String> symptoms,
    List<String> suppliesUsed = const [],
    required String treatment,
    required String remarks,
  }) async {
    final hlc = _tick();
    final visit = Visitation(
      id: const Uuid().v4(),
      patientId: patientId,
      symptoms: symptoms,
      suppliesUsed: suppliesUsed,
      treatment: treatment,
      remarks: remarks,
      hlc: hlc,
      nodeId: _nodeId,
    );
    await _db.insertVisitation(visit);
    if (_selectedPatient?.id == patientId) {
      _visitations = await _db.getVisitationsForPatient(patientId);
    }
    notifyListeners();
    _autoPush();
  }

  Future<int> getTodayVisitCount() async {
    return await _db.getTodayVisitCount();
  }

  // ── Granular sync refresh ────────────────────────────────────────

  /// Called by SyncProvider after a batch merge completes.
  /// Only triggers notifyListeners if the changed IDs intersect with
  /// the currently displayed page.
  Future<void> onSyncComplete(Set<String> changedIds) async {
    _lastSyncChangedIds = changedIds;

    // Check if any currently displayed patient was affected
    final displayedIds = _patients.map((p) => p.id).toSet();
    final needsRefresh = displayedIds.intersection(changedIds).isNotEmpty;

    if (needsRefresh) {
      await loadPatients();
    }

    // If the selected patient was updated, refresh it
    if (_selectedPatient != null && changedIds.contains(_selectedPatient!.id)) {
      final refreshed = await _db.getPatient(_selectedPatient!.id);
      _selectedPatient = refreshed;
      if (_selectedPatient != null) {
        _visitations = await _db.getVisitationsForPatient(_selectedPatient!.id);
      }
      notifyListeners();
    }
  }
}
