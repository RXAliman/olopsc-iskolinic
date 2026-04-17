import 'dart:async';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';
import '../crdt/hlc.dart';
import '../crdt/node_id.dart';
import '../providers/inventory_provider.dart';
import 'package:uuid/uuid.dart';

class PatientProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Reference to SyncProvider for auto-push after writes.
  /// Set via [setOnLocalWrite] after both providers are created.
  VoidCallback? _onLocalWrite;

  /// Reference to InventoryProvider for auto-deduction on visitation.
  InventoryProvider? _inventoryProvider;

  /// Debounce timer — collapses rapid writes into a single push.
  Timer? _pushDebounce;
  static const _pushDebounceDelay = Duration(milliseconds: 200);

  // Current HLC state (loaded once on init)
  HLC _clock = const HLC(timestamp: 0, counter: 0, nodeId: '');
  String _nodeId = '';

  // Paginated patient data
  List<Patient> _patients = [];
  int _totalPatients = 0;
  int _allPatientsCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;
  String _searchQuery = '';
  bool _loading = false;

  // Selected patient & visitations
  List<Visitation> _visitations = [];
  Patient? _selectedPatient;
  int _currentVisitPage = 0;
  int _totalVisitations = 0;
  final int _visitPageSize = 10;
  int _todayVisits = 0;

  // Dashboard Visitations list state
  int _dashboardVisitPage = 0;
  final int _dashboardVisitPageSize = 3;
  List<Map<String, dynamic>> _dashboardVisits = [];

  // IDs of records changed by the last sync (for granular rebuild)
  Set<String> _lastSyncChangedIds = {};

  List<Patient> get patients => _patients;
  int get totalPatients => _totalPatients;
  int get allPatientsCount => _allPatientsCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalPatients / _pageSize).ceil();
  Patient? get selectedPatient => _selectedPatient;
  List<Visitation> get visitations => _visitations;
  int get currentVisitPage => _currentVisitPage;
  int get totalVisitPages => (_totalVisitations / _visitPageSize).ceil();
  int get totalVisitations => _totalVisitations;
  int get visitPageSize => _visitPageSize;
  int get todayVisits => _todayVisits;

  List<Map<String, dynamic>> get dashboardVisits => _dashboardVisits;
  int get dashboardVisitPage => _dashboardVisitPage;
  int get dashboardVisitPageSize => _dashboardVisitPageSize;
  int get totalDashboardVisitPages =>
      (_todayVisits / _dashboardVisitPageSize).ceil();

  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  Set<String> get lastSyncChangedIds => _lastSyncChangedIds;

  /// Register a callback that fires after every local write (used for auto-push sync).
  void setOnLocalWrite(VoidCallback callback) {
    _onLocalWrite = callback;
  }

  /// Set reference to InventoryProvider for auto-deduction.
  void setInventoryProvider(InventoryProvider provider) {
    _inventoryProvider = provider;
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

    _allPatientsCount = await _db.getPatientCount();

    if (_searchQuery.isEmpty) {
      _totalPatients = _allPatientsCount;
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

  /// Reloads patients, today's visits, and patient-specific visits if any.
  Future<void> refreshAll() async {
    await loadPatients();
    await loadTodayVisits();
    if (_selectedPatient != null) {
      await loadVisitations();
    }
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
    final withCrdt = patient.copyWith(hlc: hlc, nodeId: _nodeId);
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
    await loadTodayVisits();
    _autoPush();
  }

  Future<void> selectPatient(Patient patient) async {
    _selectedPatient = patient;
    _currentVisitPage = 0;
    await loadVisitations();
    notifyListeners();
  }

  Future<void> loadVisitations() async {
    if (_selectedPatient == null) return;
    final offset = _currentVisitPage * _visitPageSize;
    _totalVisitations = await _db.getVisitationCountForPatient(
      _selectedPatient!.id,
    );
    _visitations = await _db.getVisitationsPaginated(
      _selectedPatient!.id,
      _visitPageSize,
      offset,
    );
    notifyListeners();
  }

  void goToVisitPage(int page) {
    if (page < 0 || (totalVisitPages > 0 && page >= totalVisitPages)) return;
    _currentVisitPage = page;
    loadVisitations();
  }

  void nextVisitPage() => goToVisitPage(_currentVisitPage + 1);
  void prevVisitPage() => goToVisitPage(_currentVisitPage - 1);
  void firstVisitPage() => goToVisitPage(0);
  void lastVisitPage() =>
      goToVisitPage((totalVisitPages > 0 ? totalVisitPages : 1) - 1);

  Future<void> updateVisitation(Visitation visit) async {
    // Before updating, get original to see if new supplies were added
    final original = await _db.getVisitation(visit.id);
    
    final updatedVisit = visit.copyWith(hlc: _tick());
    await _db.updateVisitation(updatedVisit);

    // If it's a new consumption (not in original), deduct stock
    if (original != null) {
      final originalSet = original.consumedSupplies.toSet();
      for (final supplyStr in visit.consumedSupplies) {
        if (!originalSet.contains(supplyStr)) {
          final id = supplyStr.contains(':') ? supplyStr.split(':')[0] : supplyStr;
          await _inventoryProvider?.deductStock(id, 1);
        }
      }
    }
    
    await loadTodayVisits();
    if (_selectedPatient?.id == visit.patientId) {
      await loadVisitations();
    } else {
      notifyListeners();
    }
    _autoPush();
  }

  Future<void> deleteVisitation(Visitation visit) async {
    final deletedVisit = visit.copyWith(isDeleted: true, hlc: _tick());
    await _db.updateVisitation(deletedVisit);
    
    // Inventory restocking is complex due to FEFO, omitted for now.
    
    await loadTodayVisits();
    if (_selectedPatient?.id == visit.patientId) {
      if (_visitations.length == 1 && _currentVisitPage > 0) {
        _currentVisitPage--;
      }
      await loadVisitations();
    } else {
      notifyListeners();
    }
    _autoPush();
  }

  Future<void> addVisitation({
    required String patientId,
    required List<String> symptoms,
    List<String> suppliesUsed = const [],
    List<String> consumedSupplies = const [],
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

    // Conditionally deduct stock
    for (final supplyStr in consumedSupplies) {
      // Resolve ID if it's in ID:Name format
      final id = supplyStr.contains(':') ? supplyStr.split(':')[0] : supplyStr;
      await _inventoryProvider?.deductStock(id, 1);
    }

    await loadTodayVisits();

    if (_selectedPatient?.id == patientId) {
      _currentVisitPage = 0;
      await loadVisitations();
    } else {
      notifyListeners();
    }
    _autoPush();
  }

  Future<void> loadTodayVisits() async {
    _todayVisits = await _db.getTodayVisitCount();
    await loadDashboardVisits();
  }

  Future<void> loadDashboardVisits() async {
    final offset = _dashboardVisitPage * _dashboardVisitPageSize;
    _dashboardVisits = await _db.getTodayVisitationsPaginated(
      _dashboardVisitPageSize,
      offset,
    );
    notifyListeners();
  }

  void goToDashboardVisitPage(int page) {
    if (page < 0 ||
        (totalDashboardVisitPages > 0 && page >= totalDashboardVisitPages)) {
      return;
    }
    _dashboardVisitPage = page;
    loadDashboardVisits();
  }

  void nextDashboardVisitPage() =>
      goToDashboardVisitPage(_dashboardVisitPage + 1);
  void prevDashboardVisitPage() =>
      goToDashboardVisitPage(_dashboardVisitPage - 1);
  void firstDashboardVisitPage() => goToDashboardVisitPage(0);
  void lastDashboardVisitPage() => goToDashboardVisitPage(
    (totalDashboardVisitPages > 0 ? totalDashboardVisitPages : 1) - 1,
  );

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
