import 'package:flutter/material.dart';

/// Stub auth provider — works offline with a hardcoded admin account.
/// Replace with Firebase Auth when the Firebase project is configured.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _adminEmail = '';
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  String get adminEmail => _adminEmail;
  String? get error => _error;

  // Default admin credentials (for offline / demo mode)
  static const _defaultEmail = 'admin@clinic.app';
  static const _defaultPassword = 'admin123';

  Future<bool> login(String email, String password) async {
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (email == _defaultEmail && password == _defaultPassword) {
      _isLoggedIn = true;
      _adminEmail = email;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = 'Invalid email or password';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _adminEmail = '';
    _error = null;
    notifyListeners();
  }
}
