import '../models/order.dart';
import '../models/earnings.dart';
import '../utils/dummy_data.dart';
import 'order_service.dart';

/// Earnings Service
/// Calculates and manages earnings data
class EarningsService {
  // Singleton pattern
  static final EarningsService _instance = EarningsService._internal();
  factory EarningsService() => _instance;
  EarningsService._internal();

  final OrderService _orderService = OrderService();

  /// Calculate daily earnings for a specific date
  Future<DailyEarnings> getDailyEarnings(String cookId, DateTime date) async {
    final orders = await _orderService.getOrders(cookId);
    
    // Filter orders for the specific date
    final dayOrders = orders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.year == date.year &&
             orderDate.month == date.month &&
             orderDate.day == date.day;
    }).toList();

    // Calculate metrics
    final totalOrders = dayOrders.length;
    final completedOrders = dayOrders.where((o) => o.status == OrderStatus.completed).length;
    final rejectedOrders = dayOrders.where((o) => o.status == OrderStatus.rejected).length;
    
    // Calculate total revenue from completed orders only
    final totalRevenue = dayOrders
        .where((o) => o.status == OrderStatus.completed)
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

  /// Get today's earnings
  Future<DailyEarnings> getTodayEarnings(String cookId) async {
    return await getDailyEarnings(cookId, DateTime.now());
  }

  /// Get earnings for a date range
  Future<List<DailyEarnings>> getEarningsForDateRange(
    String cookId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<DailyEarnings> earningsList = [];
    
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dailyEarnings = await getDailyEarnings(cookId, currentDate);
      earningsList.add(dailyEarnings);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return earningsList;
  }

  /// Get this week's earnings
  Future<List<DailyEarnings>> getWeeklyEarnings(String cookId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return await getEarningsForDateRange(cookId, startOfWeek, endOfWeek);
  }

  /// Get this month's earnings
  Future<List<DailyEarnings>> getMonthlyEarnings(String cookId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return await getEarningsForDateRange(cookId, startOfMonth, endOfMonth);
  }

  /// Get earnings transactions (completed orders as transactions)
  Future<List<EarningsTransaction>> getEarningsTransactions(String cookId) async {
    final orders = await _orderService.getOrders(cookId);
    
    // Filter completed orders and convert to transactions
    final completedOrders = orders
        .where((order) => order.status == OrderStatus.completed)
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
        .where((order) => order.status == OrderStatus.completed)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  /// Calculate total completed orders (all time)
  Future<int> getTotalCompletedOrders(String cookId) async {
    final orders = await _orderService.getOrders(cookId);
    return orders.where((order) => order.status == OrderStatus.completed).length;
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
