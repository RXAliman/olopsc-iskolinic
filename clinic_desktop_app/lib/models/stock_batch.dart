class StockBatch {
  final String id;
  final String itemName;
  final int quantity;
  final DateTime expirationDate;
  final DateTime createdAt;

  StockBatch({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.expirationDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'expirationDate': expirationDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockBatch.fromMap(Map<String, dynamic> map) {
    return StockBatch(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      quantity: map['quantity'] as int,
      expirationDate: DateTime.parse(map['expirationDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  StockBatch copyWith({int? quantity}) {
    return StockBatch(
      id: id,
      itemName: itemName,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate,
      createdAt: createdAt,
    );
  }
}
