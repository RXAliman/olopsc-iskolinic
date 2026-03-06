import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';

class PatientProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Paginated patient data
  List<Patient> _patients = [];
  int _totalPatients = 0;
  int _currentPage = 0;
  int _pageSize = 10;
  String _searchQuery = '';
  bool _loading = false;

  // Selected patient & visitations
  List<Visitation> _visitations = [];
  Patient? _selectedPatient;

  List<Patient> get patients => _patients;
  int get totalPatients => _totalPatients;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalPatients / _pageSize).ceil();
  Patient? get selectedPatient => _selectedPatient;
  List<Visitation> get visitations => _visitations;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;

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
    await _db.insertPatient(patient);
    await loadPatients();
  }

  Future<void> updatePatient(Patient patient) async {
    await _db.updatePatient(patient);
    await loadPatients();
    if (_selectedPatient?.id == patient.id) {
      _selectedPatient = patient;
      notifyListeners();
    }
  }

  Future<void> deletePatient(String id) async {
    await _db.deletePatient(id);
    if (_selectedPatient?.id == id) {
      _selectedPatient = null;
      _visitations = [];
    }
    // Clamp page if we deleted the last item on the last page
    if (_currentPage >= totalPages && _currentPage > 0) {
      _currentPage = totalPages - 1;
    }
    await loadPatients();
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
    final visit = Visitation(
      id: const Uuid().v4(),
      patientId: patientId,
      symptoms: symptoms,
      suppliesUsed: suppliesUsed,
      treatment: treatment,
      remarks: remarks,
    );
    await _db.insertVisitation(visit);
    if (_selectedPatient?.id == patientId) {
      _visitations = await _db.getVisitationsForPatient(patientId);
    }
    notifyListeners();
  }

  Future<int> getTodayVisitCount() async {
    return await _db.getTodayVisitCount();
  }
}
