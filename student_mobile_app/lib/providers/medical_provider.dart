import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medical_record.dart';
import '../services/database_helper.dart';

class MedicalProvider extends ChangeNotifier {
  List<MedicalRecord> _records = [];
  bool _isLoading = false;

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  int get totalRecords => _records.length;
  int get acknowledgedCount =>
      _records.where((r) => r.parentAcknowledged).length;

  final _db = DatabaseHelper.instance;

  Future<void> loadRecords(String studentId) async {
    _isLoading = true;
    notifyListeners();

    _records = await _db.getMedicalRecords(studentId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord({
    required String studentId,
    required String title,
    String description = '',
    String filePath = '',
  }) async {
    final record = MedicalRecord(
      id: const Uuid().v4(),
      studentId: studentId,
      title: title,
      description: description,
      filePath: filePath,
    );

    await _db.insertMedicalRecord(record);
    _records.insert(0, record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteMedicalRecord(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// Simulate parent acknowledging a medical record.
  Future<void> acknowledgeRecord(String id, {String notes = ''}) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final updated = _records[index].copyWith(
      parentAcknowledged: true,
      parentNotes: notes,
    );
    await _db.updateMedicalRecord(updated);
    _records[index] = updated;
    notifyListeners();
  }

  /// Simulate parent adding notes to a medical record.
  Future<void> addParentNotes(String id, String notes) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final updated = _records[index].copyWith(parentNotes: notes);
    await _db.updateMedicalRecord(updated);
    _records[index] = updated;
    notifyListeners();
  }
}
