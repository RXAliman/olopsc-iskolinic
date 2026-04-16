class InventoryItem {
  final String id;
  final String itemName;
  final int quantity;
  final int lowStockAmount;
  final String clinic;
  final String itemType; // 'piece' or 'bottle'
  final DateTime createdAt;

  // CRDT fields
  final String hlc;
  final String nodeId;
  final bool isDeleted;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.lowStockAmount,
    required this.clinic,
    required this.itemType,
    required this.hlc,
    required this.nodeId,
    this.isDeleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isLowStock => quantity <= lowStockAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'lowStockAmount': lowStockAmount,
      'clinic': clinic,
      'itemType': itemType,
      'createdAt': createdAt.toIso8601String(),
      'hlc': hlc,
      'nodeId': nodeId,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      quantity: map['quantity'] as int,
      lowStockAmount: map['lowStockAmount'] as int,
      clinic: map['clinic'] as String,
      itemType: map['itemType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      hlc: map['hlc'] as String? ?? '',
      nodeId: map['nodeId'] as String? ?? '',
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'lowStockAmount': lowStockAmount,
      'clinic': clinic,
      'itemType': itemType,
      'createdAt': createdAt.toIso8601String(),
      'hlc': hlc,
      'nodeId': nodeId,
      'isDeleted': isDeleted,
    };
  }

  factory InventoryItem.fromSyncMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      quantity: map['quantity'] as int,
      lowStockAmount: map['lowStockAmount'] as int,
      clinic: map['clinic'] as String,
      itemType: map['itemType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      hlc: map['hlc'] as String,
      nodeId: map['nodeId'] as String,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  InventoryItem copyWith({
    String? itemName,
    int? quantity,
    int? lowStockAmount,
    String? clinic,
    String? itemType,
    String? hlc,
    String? nodeId,
    bool? isDeleted,
  }) {
    return InventoryItem(
      id: id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      lowStockAmount: lowStockAmount ?? this.lowStockAmount,
      clinic: clinic ?? this.clinic,
      itemType: itemType ?? this.itemType,
      createdAt: createdAt,
      hlc: hlc ?? this.hlc,
      nodeId: nodeId ?? this.nodeId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
