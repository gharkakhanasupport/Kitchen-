import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../utils/supabase_config.dart';
import 'sync_service.dart';

/// Order Service
/// Manages orders with Supabase persistence and dual-write sync.
/// Listens for incoming orders from User App via Supabase Realtime.
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final SyncService _sync = SyncService();
  static const String _table = 'orders';

  // Cache for orders
  List<Order>? _orders;

  // Stream controller for local UI reactivity
  final _orderUpdateController = StreamController<List<Order>>.broadcast();
  Stream<List<Order>> get orderUpdates => _orderUpdateController.stream;

  // Supabase realtime subscription
  StreamSubscription? _realtimeSubscription;

  /// Start listening for real-time order updates from both DBs.
  /// Call this once during app initialization.
  void startRealtimeListener(String cookId) {
    // Listen to Kitchen DB for incoming orders (written by User App)
    final stream = SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('cook_id', cookId)
        .order('created_at', ascending: false);

    _realtimeSubscription = stream.listen((data) {
      _orders = data.map((row) => Order.fromMap(row)).toList();
      _orderUpdateController.add(_orders!);
    });
  }

  /// Get all orders for current cook
  Future<List<Order>> getOrders(String cookId) async {
    if (_orders != null) return _orders!;

    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .order('created_at', ascending: false);

      _orders = data.map((row) => Order.fromMap(row)).toList();
      return _orders!;
    } catch (e) {
      debugPrint('OrderService.getOrders error: $e');
      _orders = [];
      return _orders!;
    }
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(
    String cookId,
    OrderStatus status,
  ) async {
    final orders = await getOrders(cookId);
    return orders.where((order) => order.status == status).toList();
  }

  /// Get pending orders
  Future<List<Order>> getPendingOrders(String cookId) async {
    return await getOrdersByStatus(cookId, OrderStatus.pending);
  }

  /// Get active orders (accepted, preparing, ready)
  Future<List<Order>> getActiveOrders(String cookId) async {
    final orders = await getOrders(cookId);
    return orders
        .where(
          (order) =>
              order.status == OrderStatus.accepted ||
              order.status == OrderStatus.preparing ||
              order.status == OrderStatus.ready,
        )
        .toList();
  }

  /// Get completed orders
  Future<List<Order>> getCompletedOrders(String cookId) async {
    return await getOrdersByStatus(cookId, OrderStatus.completed);
  }

  /// Accept an order (synced to both DBs)
  Future<bool> acceptOrder(String orderId) async {
    try {
      final updateData = {
        'status': OrderStatus.accepted.name,
        'accepted_at': DateTime.now().toIso8601String(),
      };

      await _sync.dualUpdate(_table, updateData, orderId);
      await _refreshLocalCache(orderId, updateData);
      return true;
    } catch (e) {
      debugPrint('OrderService.acceptOrder error: $e');
      return false;
    }
  }

  /// Reject an order (synced to both DBs)
  Future<bool> rejectOrder(String orderId) async {
    try {
      final updateData = {'status': OrderStatus.rejected.name};

      await _sync.dualUpdate(_table, updateData, orderId);
      await _refreshLocalCache(orderId, updateData);
      return true;
    } catch (e) {
      debugPrint('OrderService.rejectOrder error: $e');
      return false;
    }
  }

  /// Update order status (synced to both DBs)
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus.name};
      if (newStatus == OrderStatus.completed) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _sync.dualUpdate(_table, updateData, orderId);
      await _refreshLocalCache(orderId, updateData);
      return true;
    } catch (e) {
      debugPrint('OrderService.updateOrderStatus error: $e');
      return false;
    }
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('id', orderId)
          .maybeSingle();

      return data != null ? Order.fromMap(data) : null;
    } catch (e) {
      debugPrint('OrderService.getOrderById error: $e');
      return null;
    }
  }

  /// Get today's orders count
  Future<int> getTodayOrdersCount(String cookId) async {
    final orders = await getOrders(cookId);
    final today = DateTime.now();

    return orders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).length;
  }

  /// Add a new order (incoming from User App or manually)
  Future<void> addNewOrder(Order order) async {
    try {
      await _sync.dualInsert(_table, order.toMap());
      // Cache will be updated by realtime listener
    } catch (e) {
      debugPrint('OrderService.addNewOrder error: $e');
    }
  }

  /// Refresh local cache after an update
  Future<void> _refreshLocalCache(
    String orderId,
    Map<String, dynamic> updateData,
  ) async {
    if (_orders == null) return;

    final index = _orders!.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _orders![index];
      _orders![index] = old.copyWith(
        status: updateData.containsKey('status')
            ? orderStatusFromString(updateData['status'])
            : null,
        acceptedAt: updateData['accepted_at'] != null
            ? DateTime.parse(updateData['accepted_at'])
            : null,
        completedAt: updateData['completed_at'] != null
            ? DateTime.parse(updateData['completed_at'])
            : null,
      );
      _orderUpdateController.add(_orders!);
    }
  }

  /// Clear local cache
  void clearCache() {
    _orders = null;
  }

  /// Dispose resources
  void dispose() {
    _realtimeSubscription?.cancel();
    _orderUpdateController.close();
  }
}
