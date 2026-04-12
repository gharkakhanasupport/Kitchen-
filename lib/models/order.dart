/// Enum representing different order statuses
enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  completed,
  rejected,
}

/// Model class representing an Order Item (item within an order)
class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  /// Create OrderItem from Map (supports both snake_case and camelCase)
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menu_item_id'] ?? map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  /// Convert OrderItem to Map (snake_case for DB)
  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': menuItemId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  /// Calculate total price for this item
  double get totalPrice => price * quantity;
}

/// Parse OrderStatus from string
OrderStatus orderStatusFromString(String status) {
  return OrderStatus.values.firstWhere(
    (e) => e.name == status,
    orElse: () => OrderStatus.pending,
  );
}

/// Model class representing a complete Order
class Order {
  final String id;
  final String cookId;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.cookId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  /// Create Order from Supabase row (snake_case)
  factory Order.fromMap(Map<String, dynamic> map) {
    // Items can be a JSONB array from Supabase or a List from local
    List<OrderItem> parsedItems = [];
    final rawItems = map['items'];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((item) => OrderItem.fromMap(
              item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item)))
          .toList();
    }

    return Order(
      id: (map['id'] ?? '').toString(),
      cookId: map['cook_id'] ?? map['cookId'] ?? '',
      customerId: map['customer_id'] ?? map['customerId'],
      customerName: map['customer_name'] ?? map['customerName'] ?? '',
      customerPhone: map['customer_phone'] ?? map['customerPhone'] ?? '',
      deliveryAddress: map['delivery_address'] ?? map['deliveryAddress'] ?? '',
      items: parsedItems,
      totalAmount: (map['total_amount'] ?? map['totalAmount'] ?? 0).toDouble(),
      status: orderStatusFromString(
        map['status'] ?? 'pending',
      ),
      createdAt: DateTime.parse(
        map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'])
          : map['acceptedAt'] != null
              ? DateTime.parse(map['acceptedAt'])
              : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
    );
  }

  /// Convert Order to Supabase-compatible map (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'cook_id': cookId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'status': status.name,
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Convert to map including ID (for upserts)
  Map<String, dynamic> toMapWithId() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// Create a copy of Order with some fields updated
  Order copyWith({
    String? id,
    String? cookId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return Order(
      id: id ?? this.id,
      cookId: cookId ?? this.cookId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  /// Get total number of items in order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
