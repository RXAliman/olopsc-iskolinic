import 'package:hive_ce_flutter/adapters.dart';
import 'package:vvella/services/constants.dart';

class HealthLogService {
  static final _bloodPressureLogBox = Hive.box(bloodPressureLogBoxName);
  static final _bloodSugarLogBox = Hive.box(bloodSugarLogBoxName);
  static final _exerciseLogBox = Hive.box(exerciseLogBoxName);
  static final _mealLogBox = Hive.box(mealLogBoxName);
  static final _sleepLogBox = Hive.box(sleepLogBoxName);
  static final _waterIntakeLogBox = Hive.box(waterIntakeLogBoxName);
  static final _weightLogBox = Hive.box(weightLogBoxName);

  static Future<void> addBloodPressureLog({
    required DateTime date,
    required int systolic, // in mmHg (millimeter of mercury)
    required int diastolic, // in mmHg
  }) => _bloodPressureLogBox.add({
    'date': date.toString(),
    'systolic': systolic,
    'diastolic': diastolic,
  });

  static Future<void> addBloodSugarLog({
    required DateTime date, 
    required double readingInMilligramPerDeciliter,
  }) => _bloodSugarLogBox.add({
    'date': date.toString(),
    'readingInMilligramPerDeciliter': readingInMilligramPerDeciliter,
  });

  static Future<void> addExerciseLog({
    required DateTime datetime,
    required String type,
    required int durationInSeconds,
    String? description,
  }) => _exerciseLogBox.add({
    'datetime': datetime.toString(),
    'type': type,
    'durationInSeconds': durationInSeconds,
    'description': description ?? '',
  });

  static Future<void> addMealLog({
    required DateTime datetime,
    required String type,
    required String contents,
  }) => _mealLogBox.add({
    'datetime': datetime.toString(),
    'type': type,
    'contents': contents,
  });

  static Future<void> addSleepLog({
    required DateTime date,
    required String quality,
    int? durationInHours,
  }) => _sleepLogBox.add({
    'date': date.toString(),
    'quality': quality,
    'durationInHours': durationInHours,
  });

  static Future<void> addWaterIntakeLog({
    required DateTime datetime,
    required int quantity,
    required String unit, // cups, ounces, or bottle
  }) => _waterIntakeLogBox.add({
    'datetime': datetime,
    'quantity': quantity,
    'unit': unit,
  });

  static Future<void> addWeightLog({
    required DateTime date,
    required double weightInKilograms,
  }) => _weightLogBox.add({
    'date': date,
    'weightInKilograms': weightInKilograms,
  });

  static Map? getLatestBloodPressureLog() {
    if (_bloodPressureLogBox.isEmpty) {
      return null;
    }

    final List<Map<dynamic, dynamic>> entries = 
        _bloodPressureLogBox.values.map((e) => e as Map<dynamic, dynamic>).toList();
    
    // 2. Sort the list in descending order based on the 'date' string attribute.
    entries.sort((a, b) {
      final String dateAStr = a['date'] as String;
      final String dateBStr = b['date'] as String;
      
      try {
        // CRITICAL STEP: Parse the string back into DateTime for accurate comparison
        final DateTime dateA = DateTime.parse(dateAStr);
        final DateTime dateB = DateTime.parse(dateBStr);

        // Sort descending (b vs a) to get the newest date first
        return dateB.compareTo(dateA); 
      } catch (e) {
        // Handle case where date string is malformed or missing
        print('Date Parsing Error in Hive entry: $e');
        // Treat unparsable dates as older entries
        return 1; 
      }
    }); 

    return entries.first;
  }

  static Map? getLatestBloodSugarLog() {
    if (_bloodSugarLogBox.isEmpty) {
      return null;
    }

    final List<Map<dynamic, dynamic>> entries = 
        _bloodSugarLogBox.values.map((e) => e as Map<dynamic, dynamic>).toList();
    
    // 2. Sort the list in descending order based on the 'date' string attribute.
    entries.sort((a, b) {
      final String dateAStr = a['date'] as String;
      final String dateBStr = b['date'] as String;
      
      try {
        // CRITICAL STEP: Parse the string back into DateTime for accurate comparison
        final DateTime dateA = DateTime.parse(dateAStr);
        final DateTime dateB = DateTime.parse(dateBStr);

        // Sort descending (b vs a) to get the newest date first
        return dateB.compareTo(dateA); 
      } catch (e) {
        // Handle case where date string is malformed or missing
        print('Date Parsing Error in Hive entry: $e');
        // Treat unparsable dates as older entries
        return 1; 
      }
    }); 

    return entries.first;
  }

  static Map? getLatestWeightLog() {
    if (_weightLogBox.isEmpty) {
      return null;
    }

    final List<Map<dynamic, dynamic>> entries = 
        _weightLogBox.values.map((e) => e as Map<dynamic, dynamic>).toList();
    
    // 2. Sort the list in descending order based on the 'date' string attribute.
    entries.sort((a, b) {
      final String dateAStr = a['date'] as String;
      final String dateBStr = b['date'] as String;
      
      try {
        // CRITICAL STEP: Parse the string back into DateTime for accurate comparison
        final DateTime dateA = DateTime.parse(dateAStr);
        final DateTime dateB = DateTime.parse(dateBStr);

        // Sort descending (b vs a) to get the newest date first
        return dateB.compareTo(dateA); 
      } catch (e) {
        // Handle case where date string is malformed or missing
        print('Date Parsing Error in Hive entry: $e');
        // Treat unparsable dates as older entries
        return 1; 
      }
    }); 

    return entries.first;
  }
}