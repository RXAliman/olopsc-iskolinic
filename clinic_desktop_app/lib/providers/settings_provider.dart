import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyConnectionMode = 'connection_mode';
  static const String _keyRetentionYears = 'retention_years';
  static const String _keyDeveloperMode = 'developer_mode';
  static const String _keyLanServerIp = 'lan_server_ip';

  // 0: Offline, 1: LAN, 2: Relay
  int _connectionMode = 2;
  int get connectionMode => _connectionMode;

  String _lanServerIp = 'localhost';
  String get lanServerIp => _lanServerIp;

  /// Dynamically resolves the LAN WebSocket URL, avoiding double-ports if the user specified a custom port
  String get lanWsUrl {
    final ip = _lanServerIp.trim();
    if (ip.startsWith('ws://') || ip.startsWith('wss://')) {
      return ip;
    }
    if (ip.contains(':')) {
      return 'ws://$ip/ws';
    }
    return 'ws://$ip:8090/ws';
  }

  int _retentionYears = 5;
  int get retentionYears => _retentionYears;

  bool _isDeveloperMode = false;
  bool get isDeveloperMode => _isDeveloperMode;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _connectionMode = prefs.getInt(_keyConnectionMode) ?? 2;
    _retentionYears = prefs.getInt(_keyRetentionYears) ?? 5;
    _isDeveloperMode = prefs.getBool(_keyDeveloperMode) ?? false;
    _lanServerIp = prefs.getString(_keyLanServerIp) ?? 'localhost';
    _initialized = true;
    notifyListeners();
  }

  /// Update and persist connection mode
  Future<void> updateConnectionMode(int mode) async {
    if (mode == _connectionMode) return;

    _connectionMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConnectionMode, mode);
  }

  /// Update and persist LAN Server IP
  Future<void> updateLanServerIp(String ip) async {
    if (ip == _lanServerIp) return;
    _lanServerIp = ip;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanServerIp, ip);
  }

  /// Update and persist retention years
  Future<void> updateRetentionYears(int years) async {
    if (years == _retentionYears) return;
    _retentionYears = years;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRetentionYears, years);
  }

  /// Toggle and persist developer mode
  Future<void> toggleDeveloperMode(bool value) async {
    if (value == _isDeveloperMode) return;
    _isDeveloperMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDeveloperMode, value);
  }
}
