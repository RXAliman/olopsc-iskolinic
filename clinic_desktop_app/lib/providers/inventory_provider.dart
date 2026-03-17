import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_batch.dart';
import '../services/database_helper.dart';

class InventoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Aggregated inventory: itemName → total quantity
  Map<String, int> _summary = {};

  /// All stock batches (with qty > 0), sorted by item then expiry
  List<StockBatch> _batches = [];

  Map<String, int> get summary => _summary;
  List<StockBatch> get batches => _batches;

  /// Get batches for a specific item, grouped by expiry
  List<StockBatch> batchesForItem(String itemName) {
    return _batches.where((b) => b.itemName == itemName).toList();
  }

  /// Load both summary and detailed batches
  Future<void> loadInventory() async {
    _summary = await _db.getInventorySummary();
    _batches = await _db.getAllStockBatches();
    notifyListeners();
  }

  /// Add a new stock batch
  Future<void> addStock({
    required String itemName,
    required int quantity,
    required DateTime expirationDate,
  }) async {
    final batch = StockBatch(
      id: const Uuid().v4(),
      itemName: itemName,
      quantity: quantity,
      expirationDate: expirationDate,
    );
    await _db.insertStockBatch(batch);
    await loadInventory();
  }

  /// Deduct stock using FEFO (called when visitation uses supplies)
  Future<void> deductStock(String itemName, int qty) async {
    await _db.deductStock(itemName, qty);
    await loadInventory();
  }

  /// Manual removal (same as deduct but explicit)
  Future<void> removeStock(String itemName, int qty) async {
    await deductStock(itemName, qty);
  }
}
