import 'package:hive_ce_flutter/hive_flutter.dart';

class HealthRepository {
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('health_data');
  }

  Future<void> saveRecord(Map<String, dynamic> data) async {
    // Add timestamp
    data['timestamp'] = DateTime.now().toIso8601String();
    await _box.add(data);
  }

  List<Map<String, dynamic>> getLastRecords(int count) {
      if (!_box.isOpen) return [];
      
      final records = _box.values.toList().cast<Map>();
      // Convert to Map<String, dynamic> safely
      final List<Map<String, dynamic>> result = [];
      for(var r in records) {
          result.add(Map<String, dynamic>.from(r));
      }
      
      // Sort desc
      result.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      
      if (result.length > count) {
          return result.sublist(0, count);
      }
      return result;
  }
}
