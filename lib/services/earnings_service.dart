import '../models/order.dart';
import '../models/earnings.dart';
import '../utils/dummy_data.dart';
import 'order_service.dart';

/// Earnings Service
/// Calculates and manages earnings data.
///
/// ## Performance Note (Fix for 44K request spike)
/// Previously, `getEarningsForDateRange()` called `getOrders()` once per day
/// in the range (e.g. 30 calls for a monthly view). Now it fetches orders
/// ONCE and filters locally by date, reducing DB calls by ~97%.
class EarningsService {
  // Singleton pattern
  static final EarningsService _instance = EarningsService._internal();
  factory EarningsService() => _instance;
  EarningsService._internal();

  final OrderService _orderService = OrderService();

  /// Calculate daily earnings for a specific date using pre-fetched orders.
  /// If [allOrders] is provided, no DB call is made (local filter only).
  DailyEarnings _calculateDailyEarnings(
    String cookId,
    DateTime date,
    List<Order> allOrders,
  ) {
    // Filter orders for the specific date
    final dayOrders = allOrders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.year == date.year &&
             orderDate.month == date.month &&
             orderDate.day == date.day;
    }).toList();

    // Calculate metrics
    final totalOrders = dayOrders.length;
    final completedOrders = dayOrders.where((o) =>
        o.status == OrderStatus.completed || o.status == OrderStatus.delivered).length;
    final rejectedOrders = dayOrders.where((o) => o.status == OrderStatus.rejected).length;

    // Calculate total revenue from completed/delivered orders only
    final totalRevenue = dayOrders
        .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return DailyEarnings(
      cookId: cookId,
      date: date,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      rejectedOrders: rejectedOrders,
    );
  }

  /// Calculate daily earnings for a specific date.
  /// Single DB call — fetches orders once, filters locally.
  Future<DailyEarnings> getDailyEarnings(String cookId, DateTime date) async {
    final orders = await _orderService.getOrders(cookId);
    return _calculateDailyEarnings(cookId, date, orders);
  }

  /// Get today's earnings — single DB call.
  Future<DailyEarnings> getTodayEarnings(String cookId) async {
    return await getDailyEarnings(cookId, DateTime.now());
  }

  /// Get earnings for a date range.
  /// ⚡ FIXED: Fetches orders ONCE, then filters locally per day.
  /// Previously did N DB calls (one per day in range).
  Future<List<DailyEarnings>> getEarningsForDateRange(
    String cookId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // ONE database call for the entire range
    final allOrders = await _orderService.getOrders(cookId);

    final List<DailyEarnings> earningsList = [];
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // Pure local computation — no DB call
      earningsList.add(_calculateDailyEarnings(cookId, currentDate, allOrders));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return earningsList;
  }

  /// Get this week's earnings — single DB call.
  Future<List<DailyEarnings>> getWeeklyEarnings(String cookId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return await getEarningsForDateRange(cookId, startOfWeek, endOfWeek);
  }

  /// Get this month's earnings — single DB call.
  Future<List<DailyEarnings>> getMonthlyEarnings(String cookId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return await getEarningsForDateRange(cookId, startOfMonth, endOfMonth);
  }

  /// Get earnings transactions (completed orders as transactions)
  Future<List<EarningsTransaction>> getEarningsTransactions(String cookId) async {
    final orders = await _orderService.getOrders(cookId);

    // Filter completed/delivered orders and convert to transactions
    final completedOrders = orders
        .where((order) =>
            order.status == OrderStatus.completed ||
            order.status == OrderStatus.delivered)
        .toList();

    // Sort by completion time (most recent first)
    completedOrders.sort((a, b) =>
      (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt)
    );

    // Convert to transactions
    return completedOrders.map((order) {
      return EarningsTransaction(
        id: 'txn_${order.id}',
        orderId: order.id,
        customerName: order.customerName,
        amount: order.totalAmount,
        timestamp: order.completedAt ?? order.createdAt,
      );
    }).toList();
  }

  /// Get today's transactions
  Future<List<EarningsTransaction>> getTodayTransactions(String cookId) async {
    final transactions = await getEarningsTransactions(cookId);
    final today = DateTime.now();

    return transactions.where((txn) {
      final txnDate = txn.timestamp;
      return txnDate.year == today.year &&
             txnDate.month == today.month &&
             txnDate.day == today.day;
    }).toList();
  }

  /// Calculate total earnings (all time)
  Future<double> getTotalEarnings(String cookId) async {
    final orders = await _orderService.getOrders(cookId);

    return orders
        .where((order) =>
            order.status == OrderStatus.completed ||
            order.status == OrderStatus.delivered)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  /// Calculate total completed orders (all time)
  Future<int> getTotalCompletedOrders(String cookId) async {
    final orders = await _orderService.getOrders(cookId);
    return orders.where((order) =>
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.delivered).length;
  }

  /// Get sample earnings data (for demo)
  DailyEarnings getSampleDailyEarnings(String cookId) {
    return DummyData.getSampleDailyEarnings(cookId);
  }

  /// Get sample transactions (for demo)
  List<EarningsTransaction> getSampleTransactions() {
    return DummyData.getSampleTransactions();
  }
}
