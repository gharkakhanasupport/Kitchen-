/// Model class representing daily earnings
class DailyEarnings {
  final String cookId;
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final int rejectedOrders;

  DailyEarnings({
    required this.cookId,
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.rejectedOrders,
  });

  /// Create DailyEarnings from Map
  factory DailyEarnings.fromMap(Map<String, dynamic> map) {
    return DailyEarnings(
      cookId: map['cookId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      completedOrders: map['completedOrders'] ?? 0,
      rejectedOrders: map['rejectedOrders'] ?? 0,
    );
  }

  /// Convert DailyEarnings to Map
  Map<String, dynamic> toMap() {
    return {
      'cookId': cookId,
      'date': date.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'rejectedOrders': rejectedOrders,
    };
  }

  /// Calculate average order value
  double get averageOrderValue {
    if (completedOrders == 0) return 0.0;
    return totalRevenue / completedOrders;
  }

  /// Calculate acceptance rate (percentage)
  double get acceptanceRate {
    if (totalOrders == 0) return 0.0;
    return ((totalOrders - rejectedOrders) / totalOrders) * 100;
  }
}

/// Model class representing an earnings transaction
class EarningsTransaction {
  final String id;
  final String orderId;
  final String customerName;
  final double amount;
  final DateTime timestamp;

  EarningsTransaction({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.timestamp,
  });

  /// Create EarningsTransaction from Map
  factory EarningsTransaction.fromMap(Map<String, dynamic> map) {
    return EarningsTransaction(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      customerName: map['customerName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert EarningsTransaction to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'customerName': customerName,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
