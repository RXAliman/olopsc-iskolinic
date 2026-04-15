import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service for symptom follow-up reminders.
/// Stubbed for offline demo — will integrate with Firebase later.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Show an immediate notification (e.g., emergency alert sent confirmation).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'student_app_channel',
      'Student App Notifications',
      channelDescription: 'Notifications from VVella Student App',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  /// Schedule a follow-up notification (simulated).
  /// In a real app this would use zonedSchedule with tz data.
  Future<void> scheduleFollowUp({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // For demo purposes, show notification immediately with a note
    await showNotification(
      id: id,
      title: '📋 Follow-up Reminder',
      body: '$body (Scheduled for ${scheduledDate.toLocal()})',
    );
  }
}
