import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyConnectionMode = 'connection_mode';
  static const String _keyRetentionYears = 'retention_years';

  // 0: Offline, 1: LAN (Disabled), 2: Relay
  int _connectionMode = 2;
  int get connectionMode => _connectionMode;

  int _retentionYears = 5;
  int get retentionYears => _retentionYears;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _connectionMode = prefs.getInt(_keyConnectionMode) ?? 2;
    _retentionYears = prefs.getInt(_keyRetentionYears) ?? 5;
    _initialized = true;
    notifyListeners();
  }

  /// Update and persist connection mode
  Future<void> updateConnectionMode(int mode) async {
    if (mode == _connectionMode) return;

    // Safety check: Mode 1 (LAN) is currently disabled
    if (mode == 1) return;

    _connectionMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConnectionMode, mode);
  }

  /// Update and persist retention years
  Future<void> updateRetentionYears(int years) async {
    if (years == _retentionYears) return;
    _retentionYears = years;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRetentionYears, years);
  }
}
