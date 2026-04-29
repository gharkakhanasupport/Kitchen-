import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../utils/supabase_config.dart';
import 'wallet_service.dart';

/// Order Service
/// Manages orders with Supabase persistence.
/// Listens for incoming orders from User App via Supabase Realtime.
///
/// ## Sync Architecture (Phase 6 — deduplicated)
/// - Kitchen DB is the PRIMARY source for this app.
/// - Order status updates are written ONLY to Kitchen DB.
/// - The Edge Function `gkk-kitchen-sync` (deployed on User DB Supabase)
///   listens for Kitchen DB webhook triggers and syncs status, driver_id,
///   estimated_delivery_time, and kitchen_notes back to User DB.
/// - This eliminates the previous double-write race condition where both
///   client-side `SyncService.dualUpdate()` AND server-side Edge Functions
///   wrote the same status to User DB simultaneously.
/// - `SyncService` is still used for non-order tables (kitchens, menu_items,
///   daily_menus, subscribers) where no Edge Function exists.
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  static const String _table = 'orders';

  // Cache for orders
  List<Order>? _orders;

  // Stream controller for local UI reactivity
  final _orderUpdateController = StreamController<List<Order>>.broadcast();
  Stream<List<Order>> get orderUpdates => _orderUpdateController.stream;

  // Supabase realtime subscription
  StreamSubscription? _realtimeSubscription;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _activeCookId;

  /// Start listening for real-time order updates from Kitchen DB.
  /// Call this once during app initialization.
  void startRealtimeListener(String cookId) {
    // Cancel any existing subscription first (e.g., on re-login)
    _realtimeSubscription?.cancel();
    _activeCookId = cookId;

    // Listen to Kitchen DB for incoming orders (written by User App)
    final stream = SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('cook_id', cookId)
        .order('created_at', ascending: false);

    _realtimeSubscription = stream.listen(
      (data) {
        _orders = data.map((row) => Order.fromMap(row)).toList();
        _orderUpdateController.add(_orders!);
        _reconnectAttempts = 0; // reset on successful data
        debugPrint('OrderService: realtime got ${_orders!.length} orders');
      },
      onError: (error) {
        debugPrint('OrderService: realtime stream error: $error');
        _reconnectWithBackoff();
      },
      cancelOnError: false,
    );
  }

  /// Reconnect with exponential backoff (capped at max attempts).
  void _reconnectWithBackoff() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('OrderService: max reconnect attempts reached, giving up');
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(2, 60));
    Future.delayed(delay, () {
      if (_activeCookId != null) {
        debugPrint('OrderService: reconnecting attempt $_reconnectAttempts...');
        startRealtimeListener(_activeCookId!);
      }
    });
  }

  /// Get all orders for current cook.
  /// Always fetches fresh data from the DB (cache is only used as a fallback on error).
  /// The cache is kept up-to-date by the realtime listener.
  Future<List<Order>> getOrders(String cookId, {bool forceRefresh = false}) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .order('created_at', ascending: false);

      _orders = data.map((row) => Order.fromMap(row)).toList();
      _orderUpdateController.add(_orders!);
      return _orders!;
    } catch (e) {
      debugPrint('OrderService.getOrders error: $e');
      // Fallback to cache only if we have it; otherwise return empty list
      return _orders ?? [];
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

  /// Accept an order.
  /// Writes to Kitchen DB only — Edge Function `gkk-kitchen-sync` syncs to User DB.
  Future<bool> acceptOrder(String orderId) async {
    try {
      final updateData = {
        'status': orderStatusToDbString(OrderStatus.accepted),
        'accepted_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client
          .from(_table)
          .update(updateData)
          .eq('id', orderId);
      await _refreshLocalCache(orderId, updateData);
      return true;
    } catch (e) {
      debugPrint('OrderService.acceptOrder error: $e');
      return false;
    }
  }

  /// Reject an order.
  /// Writes to Kitchen DB only — Edge Function `gkk-kitchen-sync` syncs to User DB.
  Future<bool> rejectOrder(String orderId) async {
    try {
      final updateData = {'status': orderStatusToDbString(OrderStatus.rejected)};

      await SupabaseConfig.client
          .from(_table)
          .update(updateData)
          .eq('id', orderId);
      await _refreshLocalCache(orderId, updateData);
      return true;
    } catch (e) {
      debugPrint('OrderService.rejectOrder error: $e');
      return false;
    }
  }

  /// Update order status.
  /// Writes to Kitchen DB only — Edge Function `gkk-kitchen-sync` syncs to User DB.
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final updateData = <String, dynamic>{'status': orderStatusToDbString(newStatus)};
      if (newStatus == OrderStatus.completed || newStatus == OrderStatus.delivered) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await SupabaseConfig.client
          .from(_table)
          .update(updateData)
          .eq('id', orderId);
      await _refreshLocalCache(orderId, updateData);

      // Credit kitchen wallet when order is completed or delivered
      if (newStatus == OrderStatus.completed || newStatus == OrderStatus.delivered) {
        final order = await getOrderById(orderId);
        if (order != null) {
          await KitchenWalletService().creditEarning(
            order.cookId,
            order.totalAmount,
            orderId,
          );
        }
      }

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

  /// Add a new order (incoming from User App or manually).
  /// Writes to Kitchen DB only — the order originally comes from User DB
  /// via Edge Function or realtime sync.
  Future<void> addNewOrder(Order order) async {
    try {
      await SupabaseConfig.client
          .from(_table)
          .upsert(order.toMapWithId(), onConflict: 'id');
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

  /// Per-order delete — kitchen + user DB
  Future<bool> deleteOrder(String orderId) async {
    try {
      await SupabaseConfig.client.from(_table).delete().eq('id', orderId);
      try {
        await SupabaseConfig.userDbClient.from('orders').delete().eq('id', orderId);
      } catch (e) {
        debugPrint('deleteOrder: User DB mirror delete failed: $e');
      }
      _orders?.removeWhere((o) => o.id == orderId);
      if (_orders != null) _orderUpdateController.add(_orders!);
      return true;
    } catch (e) {
      debugPrint('OrderService.deleteOrder error: $e');
      return false;
    }
  }

  /// Cancel order — calls cancel_order_full RPC (Kitchen DB) which
  /// cross-PATCHes User + Delivery DBs and refunds wallet if applicable.
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'cancel_order_full',
        params: {'p_order_id': orderId},
      );
      if (result is Map && result['ok'] == true) {
        // Local cache update — mark rejected
        final idx = _orders?.indexWhere((o) => o.id == orderId) ?? -1;
        if (idx != -1 && _orders != null) {
          _orders![idx] = _orders![idx].copyWith(status: OrderStatus.rejected);
          _orderUpdateController.add(_orders!);
        }
      }
      return (result is Map ? Map<String, dynamic>.from(result) : {'ok': false});
    } catch (e) {
      debugPrint('OrderService.cancelOrder error: $e');
      return {'ok': false, 'error': e.toString()};
    }
  }

  /// DEV / BETA TOOL — wipe every order for this cook across Kitchen+User DBs.
  /// Returns number of rows deleted in Kitchen DB.
  Future<int> clearAllCookOrders(String cookId) async {
    int total = 0;
    try {
      final del = await SupabaseConfig.client
          .from(_table)
          .delete()
          .eq('cook_id', cookId)
          .select('id');
      final ids = (del as List).map((e) => e['id']).toList();
      total = ids.length;

      // Best-effort mirror delete in User DB
      if (ids.isNotEmpty) {
        try {
          await SupabaseConfig.userDbClient
              .from('orders')
              .delete()
              .inFilter('id', ids);
        } catch (e) {
          debugPrint('clearAllCookOrders: User DB mirror delete failed: $e');
        }
      }
    } catch (e) {
      debugPrint('clearAllCookOrders: $e');
      rethrow;
    }

    _orders = null;
    _orderUpdateController.add(<Order>[]);
    return total;
  }

  /// Dispose resources
  void dispose() {
    _realtimeSubscription?.cancel();
    _orderUpdateController.close();
  }
}
