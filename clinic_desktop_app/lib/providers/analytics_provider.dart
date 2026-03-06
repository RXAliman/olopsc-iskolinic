import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../constants/symptoms.dart';
import '../constants/supplies.dart';

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<String, int> _symptomCounts = {};
  Map<String, int> _supplyCounts = {};
  bool _loading = false;
  int _totalVisits = 0;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  Map<String, int> get symptomCounts => _symptomCounts;
  Map<String, int> get supplyCounts => _supplyCounts;
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
    final symptomMap = <String, int>{};
    for (final symptom in kSymptomsList) {
      symptomMap[symptom] = 0;
    }
    for (final visit in visitations) {
      for (final symptom in visit.symptoms) {
        if (symptomMap.containsKey(symptom)) {
          symptomMap[symptom] = symptomMap[symptom]! + 1;
        }
      }
    }
    _symptomCounts = symptomMap;

    // Count each supply used
    final supplyMap = <String, int>{};
    for (final supply in kSuppliesList) {
      supplyMap[supply] = 0;
    }
    for (final visit in visitations) {
      for (final supply in visit.suppliesUsed) {
        if (supplyMap.containsKey(supply)) {
          supplyMap[supply] = supplyMap[supply]! + 1;
        }
      }
    }
    _supplyCounts = supplyMap;

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
