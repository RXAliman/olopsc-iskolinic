import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/student_user.dart';
import '../services/database_helper.dart';

/// Stub auth provider — simulates Google Account login offline.
/// Replace with Firebase Auth when the Firebase project is configured.
class AuthProvider extends ChangeNotifier {
  StudentUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  StudentUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _db = DatabaseHelper.instance;

  /// Simulate Google Account login with institutional email.
  /// In production, this will use Firebase Auth with Google Sign-In.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate a successful Google sign-in with a demo account
    const demoEmail = 'student@school.edu.ph';
    const demoName = 'Juan Dela Cruz';
    const demoNumber = 'STU-2025-001';

    var user = await _db.getUserByEmail(demoEmail);
    if (user == null) {
      user = StudentUser(
        id: const Uuid().v4(),
        studentName: demoName,
        studentNumber: demoNumber,
        email: demoEmail,
      );
      await _db.insertUser(user);
    }

    _currentUser = user;
    _isLoading = false;
    _error = null;
    notifyListeners();
    return true;
  }

  /// Fallback: Email & password login (simulated).
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Try to find existing user
    var user = await _db.getUserByEmail(email);
    if (user != null) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    _error = 'Account not found. Please register first.';
    notifyListeners();
    return false;
  }

  /// Register a new student account.
  Future<bool> register({
    required String studentName,
    required String studentNumber,
    required String email,
    required String password,
    String guardianName = '',
    String guardianEmail = '',
    String phone = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Check if email already exists
    final existing = await _db.getUserByEmail(email);
    if (existing != null) {
      _isLoading = false;
      _error = 'An account with this email already exists.';
      notifyListeners();
      return false;
    }

    final user = StudentUser(
      id: const Uuid().v4(),
      studentName: studentName,
      studentNumber: studentNumber,
      email: email,
      phone: phone,
      guardianName: guardianName,
      guardianEmail: guardianEmail,
    );

    await _db.insertUser(user);
    _currentUser = user;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Simulate linking parent/guardian Google account.
  Future<bool> linkGuardianAccount(
    String guardianName,
    String guardianEmail,
  ) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = _currentUser!.copyWith(
      guardianName: guardianName,
      guardianEmail: guardianEmail,
    );
    await _db.updateUser(_currentUser!);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Update profile.
  Future<void> updateProfile({String? studentName, String? phone}) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      studentName: studentName,
      phone: phone,
    );
    await _db.updateUser(_currentUser!);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
