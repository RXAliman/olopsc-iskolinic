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
  int _totalItems = 0;
  int _currentPage = 0;
  final int _pageSize = 10;
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  bool _loading = false;
  List<InventoryItem> _lowStockItems = []; // Global list of all low stock items
  List<InventoryItem> _expiringItems = []; // Items with stocks expiring in < 3 months
  List<InventoryItem> _allItems = []; // Global list of all inventory items
  final Set<String> _pendingDeductions = {}; // Safeguard against duplicate requests

  List<InventoryItem> get items => _items;
  int get totalItems => _totalItems;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalItems / _pageSize).ceil();
  String get searchQuery => _searchQuery;
  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  bool get loading => _loading;
  List<InventoryItem> get lowStockItems => _lowStockItems;
  List<InventoryItem> get expiringItems => _expiringItems;
  List<InventoryItem> get allItems => _allItems;

  Future<void> loadInventory() async {
    _loading = true;
    notifyListeners();

    final orderBy = _getSortColumn(_sortColumnIndex);
    
    _items = await _db.searchInventoryPaginated(
      query: _searchQuery,
      limit: _pageSize,
      offset: _currentPage * _pageSize,
      orderBy: orderBy,
      ascending: _sortAscending,
    );
    
    _totalItems = await _db.getInventoryCount(_searchQuery);
    
    // Refresh global lists for dashboard/helpers
    _allItems = await _db.getAllInventoryItems();
    _lowStockItems = _allItems.where((i) => i.isLowStock).toList();
    _updateExpiringItems();
    
    _loading = false;
    notifyListeners();
  }

  void _updateExpiringItems() {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 90)); // ~3 months

    _expiringItems = _allItems.where((item) {
      return item.stocks.any((stock) {
        if (stock.expiryDate == null || stock.isDeleted || stock.amount <= 0) return false;
        return stock.expiryDate!.isBefore(threshold);
      });
    }).toList();

    // Sort expiring items by the earliest expiry date found in their stocks
    _expiringItems.sort((a, b) {
      final aEarliest = a.stocks
          .where((s) => !s.isDeleted && s.amount > 0 && s.expiryDate != null)
          .fold<DateTime?>(null, (min, s) => min == null || s.expiryDate!.isBefore(min) ? s.expiryDate : min);
      final bEarliest = b.stocks
          .where((s) => !s.isDeleted && s.amount > 0 && s.expiryDate != null)
          .fold<DateTime?>(null, (min, s) => min == null || s.expiryDate!.isBefore(min) ? s.expiryDate : min);
      
      if (aEarliest == null) return 1;
      if (bEarliest == null) return -1;
      return aEarliest.compareTo(bEarliest);
    });
  }

  String _getSortColumn(int index) {
    switch (index) {
      case 0: return 'itemName';
      case 1: return 'itemName'; // quantity is derived now, sort by name or we could do something more complex
      case 2: return 'clinic';
      case 3: return 'itemType';
      case 4: return 'lowStockAmount';
      default: return 'itemName';
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 0;
    loadInventory();
  }

  void setSort(int index, bool ascending) {
    _sortColumnIndex = index;
    _sortAscending = ascending;
    _currentPage = 0;
    loadInventory();
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      loadInventory();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      loadInventory();
    }
  }

  void firstPage() {
    _currentPage = 0;
    loadInventory();
  }

  void lastPage() {
    _currentPage = totalPages - 1;
    loadInventory();
  }

  Future<void> addNewSupplyItem({
    required String itemName,
    required int lowStockAmount,
    required String clinic,
    required String itemType,
    int? initialStockAmount,
    DateTime? initialExpiry,
  }) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();
    final itemId = const Uuid().v4();

    final item = InventoryItem(
      id: itemId,
      itemName: itemName,
      lowStockAmount: lowStockAmount,
      clinic: clinic,
      itemType: itemType,
      hlc: hlc,
      nodeId: nodeId,
    );
    await _db.insertInventoryItem(item);

    if (initialStockAmount != null && initialStockAmount > 0) {
      final stock = StockBatch(
        id: const Uuid().v4(),
        itemId: itemId,
        amount: initialStockAmount,
        expiryDate: initialExpiry,
        hlc: hlc,
        nodeId: nodeId,
      );
      await _db.insertStockBatch(stock);
    }

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

  Future<void> addStockBatch({
    required String itemId,
    required int amount,
    DateTime? expiryDate,
  }) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();

    final stock = StockBatch(
      id: const Uuid().v4(),
      itemId: itemId,
      amount: amount,
      expiryDate: expiryDate,
      hlc: hlc,
      nodeId: nodeId,
    );
    await _db.insertStockBatch(stock);
    await loadInventory();
    onLocalChange?.call();
  }

  Future<void> updateStockBatch(StockBatch stock) async {
    final nodeId = await NodeId.get();
    final updated = stock.copyWith(
      hlc: HLC.now(nodeId).pack(),
      nodeId: nodeId,
    );
    await _db.updateStockBatch(updated);
    await loadInventory();
    onLocalChange?.call();
  }

  Future<void> deleteStockBatch(String id) async {
    final nodeId = await NodeId.get();
    final hlc = HLC.now(nodeId).pack();
    await _db.deleteStockBatch(id, hlc: hlc, nodeId: nodeId);
    await loadInventory();
    onLocalChange?.call();
  }

  Future<void> deductStock(String itemId, int qty) async {
    if (_pendingDeductions.contains(itemId)) return;
    _pendingDeductions.add(itemId);
    try {
      final nodeId = await NodeId.get();
      final hlc = HLC.now(nodeId).pack();
      // FIFO deduction logic is implemented inside DatabaseHelper.deductStock
      await _db.deductStock(itemId, qty, hlc: hlc, nodeId: nodeId);
      await loadInventory();
      onLocalChange?.call();
    } finally {
      _pendingDeductions.remove(itemId);
    }
  }

  /// Resolves a supply ID or a legacy name to a display string like "Alcohol (College Clinic)"
  String getFormattedSupplyName(String idOrName) {
    try {
      final item = _allItems.firstWhere((i) => i.id == idOrName);
      if (item.clinic.isEmpty) return item.itemName;
      return "${item.itemName} - ${item.clinic}";
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
