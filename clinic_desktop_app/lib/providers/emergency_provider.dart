import 'dart:async';
import 'package:flutter/material.dart';
import '../models/emergency_alert.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';

class EmergencyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<EmergencyAlert> _alerts = [];
  int _unacknowledgedCount = 0;
  final bool _loading = false;
  Timer? _pollTimer;

  List<EmergencyAlert> get alerts => _alerts;
  int get unacknowledgedCount => _unacknowledgedCount;
  bool get loading => _loading;
  bool get hasActiveAlerts => _unacknowledgedCount > 0;

  /// Start polling for new alerts (simulates Firestore real-time listener)
  void startListening() {
    loadAlerts();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadAlerts();
    });
  }

  void stopListening() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> loadAlerts() async {
    _alerts = await _db.getEmergencyAlerts();
    _unacknowledgedCount = await _db.getUnacknowledgedAlertCount();
    notifyListeners();
  }

  Future<void> acknowledgeAlert(String id) async {
    await _db.acknowledgeAlert(id);
    await loadAlerts();
  }

  /// Simulate receiving an emergency alert (for testing purposes)
  Future<void> simulateAlert() async {
    final alert = EmergencyAlert(
      id: const Uuid().v4(),
      studentName: 'Test Student',
      studentNumber: '2024-00${DateTime.now().millisecond}',
      message: 'Emergency! I need help immediately!',
    );
    await _db.insertEmergencyAlert(alert);
    await loadAlerts();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
