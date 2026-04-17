import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyConnectionMode = 'connection_mode';
  
  // 0: Offline, 1: LAN (Disabled), 2: Relay
  int _connectionMode = 2;
  int get connectionMode => _connectionMode;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _connectionMode = prefs.getInt(_keyConnectionMode) ?? 2;
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
}
