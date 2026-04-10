import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';

class InventoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<InventoryItem> _items = [];

  List<InventoryItem> get items => _items;

  List<InventoryItem> get lowStockItems =>
      _items.where((item) => item.isLowStock).toList();

  Future<void> loadInventory() async {
    _items = await _db.getAllInventory();
    notifyListeners();
  }

  Future<void> addNewSupplyItem({
    required String itemName,
    required int initialQuantity,
    required int averageDailyUse,
    required int leadTime,
    required int safetyStock,
  }) async {
    final item = InventoryItem(
      id: const Uuid().v4(),
      itemName: itemName,
      quantity: initialQuantity,
      averageDailyUse: averageDailyUse,
      leadTime: leadTime,
      safetyStock: safetyStock,
    );
    await _db.insertInventoryItem(item);
    await loadInventory();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _db.updateInventoryItem(item);
    await loadInventory();
  }

  Future<void> addStock(String itemName, int qty) async {
    await _db.addStock(itemName, qty);
    await loadInventory();
  }

  Future<void> deductStock(String itemName, int qty) async {
    await _db.deductStock(itemName, qty);
    await loadInventory();
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteInventoryItem(id);
    await loadInventory();
  }
}
