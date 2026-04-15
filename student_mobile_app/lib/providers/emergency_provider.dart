import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_alert.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class EmergencyProvider extends ChangeNotifier {
  List<EmergencyAlert> _alerts = [];
  bool _isLoading = false;
  bool _isSending = false;

  List<EmergencyAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  int get pendingCount => _alerts.where((a) => a.isPending).length;
  bool get hasActiveAlerts => _alerts.any((a) => a.isPending);

  final _db = DatabaseHelper.instance;
  final _notifications = NotificationService.instance;

  Future<void> loadAlerts(String studentId) async {
    _isLoading = true;
    notifyListeners();

    _alerts = await _db.getEmergencyAlerts(studentId);

    _isLoading = false;
    notifyListeners();
  }

  /// Send an emergency alert to the clinic/EMS.
  Future<bool> sendEmergencyAlert({
    required String studentId,
    required String studentName,
    required String studentNumber,
    String message = '',
    String location = '',
  }) async {
    _isSending = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final alert = EmergencyAlert(
      id: const Uuid().v4(),
      studentId: studentId,
      studentName: studentName,
      studentNumber: studentNumber,
      message: message,
      location: location,
    );

    await _db.insertEmergencyAlert(alert);
    _alerts.insert(0, alert);
    _isSending = false;
    notifyListeners();

    // Show confirmation notification
    await _notifications.showNotification(
      id: alert.id.hashCode,
      title: '🚨 Emergency Alert Sent',
      body:
          'Your emergency alert has been sent to the clinic. Help is on the way.',
    );

    return true;
  }

  /// Simulate clinic acknowledging an alert (for testing).
  Future<void> simulateAcknowledge(String alertId) async {
    await _db.updateAlertStatus(alertId, 'acknowledged');
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(status: 'acknowledged');
      notifyListeners();
    }
  }

  /// Simulate alert being resolved (for testing).
  Future<void> simulateResolve(String alertId) async {
    await _db.updateAlertStatus(alertId, 'resolved');
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(status: 'resolved');
      notifyListeners();
    }
  }
}
