import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../constants/symptoms.dart';

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<String, int> _symptomCounts = {};
  bool _loading = false;
  int _totalVisits = 0;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  Map<String, int> get symptomCounts => _symptomCounts;
  bool get loading => _loading;
  int get totalVisits => _totalVisits;

  Future<void> loadAnalytics() async {
    _loading = true;
    notifyListeners();

    final visitations = await _db.getVisitationsForMonth(
      _selectedYear,
      _selectedMonth,
    );
    _totalVisits = visitations.length;

    // Count each symptom
    final counts = <String, int>{};
    for (final symptom in kSymptomsList) {
      counts[symptom] = 0;
    }
    for (final visit in visitations) {
      for (final symptom in visit.symptoms) {
        if (counts.containsKey(symptom)) {
          counts[symptom] = counts[symptom]! + 1;
        }
      }
    }
    _symptomCounts = counts;
    _loading = false;
    notifyListeners();
  }

  void setMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    loadAnalytics();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    loadAnalytics();
  }

  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    loadAnalytics();
  }
}
