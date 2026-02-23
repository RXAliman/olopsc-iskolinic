import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';

class PatientProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Patient> _patients = [];
  List<Visitation> _visitations = [];
  Patient? _selectedPatient;
  String _searchQuery = '';
  bool _loading = false;

  List<Patient> get patients => _searchQuery.isEmpty
      ? _patients
      : _patients
            .where(
              (p) =>
                  p.studentName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  p.studentNumber.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();

  Patient? get selectedPatient => _selectedPatient;
  List<Visitation> get visitations => _visitations;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  int get totalPatients => _patients.length;

  Future<void> loadPatients() async {
    _loading = true;
    notifyListeners();
    _patients = await _db.getPatients();
    _loading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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
    required String treatment,
    required String remarks,
  }) async {
    final visit = Visitation(
      id: const Uuid().v4(),
      patientId: patientId,
      symptoms: symptoms,
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
