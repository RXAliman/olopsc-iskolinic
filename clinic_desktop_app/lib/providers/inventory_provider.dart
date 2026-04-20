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
    _lowStockItems = await _db.getLowStockItems();
    _allItems = await _db.getAllInventoryItems();
    
    _loading = false;
    notifyListeners();
  }

  String _getSortColumn(int index) {
    switch (index) {
      case 0: return 'itemName';
      case 1: return 'quantity';
      case 2: return 'clinic';
      case 3: return 'itemType';
      case 4: return 'lowStockAmount';
      case 5: return '(quantity <= lowStockAmount)';
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
    if (_pendingDeductions.contains(itemId)) return;
    _pendingDeductions.add(itemId);
    try {
      final nodeId = await NodeId.get();
      final hlc = HLC.now(nodeId).pack();
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
