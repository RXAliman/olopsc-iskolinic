import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';
import '../crdt/hlc.dart';
import '../crdt/node_id.dart';

class InventoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Called to push changes after local write
  Future<void> Function()? onLocalChange;

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
    required int lowStockAmount,
    required String clinic,
    required String itemType,
  }) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();

    final item = InventoryItem(
      id: const Uuid().v4(),
      itemName: itemName,
      quantity: initialQuantity,
      lowStockAmount: lowStockAmount,
      clinic: clinic,
      itemType: itemType,
      hlc: hlc,
      nodeId: nodeId,
    );
    await _db.insertInventoryItem(item);
    await loadInventory();
    onLocalChange?.call();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final nodeId = await NodeId.get();
    final updated = item.copyWith(
      hlc: HLC.now(nodeId).pack(),
      nodeId: nodeId,
    );
    await _db.updateInventoryItem(updated);
    await loadInventory();
    onLocalChange?.call();
  }

  Future<void> addStock(String itemId, int qty) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();
    await _db.addStock(itemId, qty, hlc: hlc, nodeId: nodeId);
    await loadInventory();
    onLocalChange?.call();
  }

  Future<void> deductStock(String itemId, int qty) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();
    await _db.deductStock(itemId, qty, hlc: hlc, nodeId: nodeId);
    await loadInventory();
    onLocalChange?.call();
  }

  /// Resolves a supply ID or a legacy name to a display string like "Alcohol (College Clinic)"
  String getFormattedSupplyName(String idOrName) {
    try {
      final item = _items.firstWhere((i) => i.id == idOrName);
      if (item.clinic.isEmpty) return item.itemName;
      return "${item.itemName} (${item.clinic})";
    } catch (_) {
      // If not found by ID, it might be a legacy itemName string or newly deleted item
      return idOrName;
    }
  }

  Future<void> deleteItem(String id) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();
    await _db.deleteInventoryItemSoft(id, hlc: hlc, nodeId: nodeId);
    await loadInventory();
    onLocalChange?.call();
  }
}
