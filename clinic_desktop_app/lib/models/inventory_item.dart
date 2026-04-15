class InventoryItem {
  final String id;
  final String itemName;
  final int quantity;
  final int averageDailyUse;
  final int leadTime;
  final int safetyStock;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.averageDailyUse,
    required this.leadTime,
    required this.safetyStock,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get reorderPoint => (averageDailyUse * leadTime) + safetyStock;
  bool get isLowStock => quantity <= reorderPoint;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'averageDailyUse': averageDailyUse,
      'leadTime': leadTime,
      'safetyStock': safetyStock,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      quantity: map['quantity'] as int,
      averageDailyUse: map['averageDailyUse'] as int,
      leadTime: map['leadTime'] as int,
      safetyStock: map['safetyStock'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  InventoryItem copyWith({
    String? itemName,
    int? quantity,
    int? averageDailyUse,
    int? leadTime,
    int? safetyStock,
  }) {
    return InventoryItem(
      id: id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      averageDailyUse: averageDailyUse ?? this.averageDailyUse,
      leadTime: leadTime ?? this.leadTime,
      safetyStock: safetyStock ?? this.safetyStock,
      createdAt: createdAt,
    );
  }
}
