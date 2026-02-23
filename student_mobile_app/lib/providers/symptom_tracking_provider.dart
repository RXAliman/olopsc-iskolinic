import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class SymptomTrackingProvider extends ChangeNotifier {
  List<Visitation> _visitations = [];
  bool _isLoading = false;

  List<Visitation> get visitations => _visitations;
  bool get isLoading => _isLoading;
  int get totalVisits => _visitations.length;
  int get pendingFollowUps => _visitations
      .where((v) => v.followUpDate != null && !v.followUpCompleted)
      .length;

  final _db = DatabaseHelper.instance;
  final _notifications = NotificationService.instance;

  Future<void> loadVisitations(String studentId) async {
    _isLoading = true;
    notifyListeners();

    _visitations = await _db.getVisitations(studentId);

    _isLoading = false;
    notifyListeners();
  }

  /// Add a simulated clinic visitation (in production, clinic creates these).
  Future<void> addVisitation({
    required String studentId,
    required List<String> symptoms,
    String treatment = '',
    String remarks = '',
    DateTime? followUpDate,
  }) async {
    final visit = Visitation(
      id: const Uuid().v4(),
      studentId: studentId,
      symptoms: symptoms,
      treatment: treatment,
      remarks: remarks,
      followUpDate: followUpDate,
    );

    await _db.insertVisitation(visit);
    _visitations.insert(0, visit);
    notifyListeners();

    // Schedule follow-up notification if date is set
    if (followUpDate != null) {
      await _notifications.scheduleFollowUp(
        id: visit.id.hashCode,
        title: 'Symptom Follow-up',
        body:
            'How are you feeling? Please update your follow-up for your recent clinic visit.',
        scheduledDate: followUpDate,
      );
    }
  }

  /// Mark follow-up as completed with notes.
  Future<void> completeFollowUp(String visitId, {String notes = ''}) async {
    final index = _visitations.indexWhere((v) => v.id == visitId);
    if (index == -1) return;

    final updated = _visitations[index].copyWith(
      followUpCompleted: true,
      followUpNotes: notes,
    );
    await _db.updateVisitation(updated);
    _visitations[index] = updated;
    notifyListeners();
  }

  /// Simulate adding a demo visitation for testing.
  Future<void> simulateVisitation(String studentId) async {
    final followUp = DateTime.now().add(const Duration(days: 2));
    await addVisitation(
      studentId: studentId,
      symptoms: ['Headache', 'Fever'],
      treatment: 'Paracetamol 500mg, rest advised',
      remarks: 'Student visited with mild complaints. Monitor for 2 days.',
      followUpDate: followUp,
    );
  }
}
