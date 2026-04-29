import 'package:flutter/foundation.dart';
import '../models/token_user.dart';
import '../utils/supabase_config.dart';
import 'profile_service.dart';

/// Token User Service
/// Derives customer list from the `orders` table — any customer who has
/// placed at least one order with the current cook is a "token user".
class TokenUserService {
  final _profileService = ProfileService();

  // Cache of derived users for sync getters
  List<TokenUser> _cache = [];

  /// Get all users (customers who have ordered from this cook)
  Future<List<TokenUser>> getTokenUsers() async {
    try {
      final cook = await _profileService.getCurrentProfile();
      if (cook == null) {
        debugPrint('TokenUserService: no cook profile — returning empty');
        _cache = [];
        return _cache;
      }

      // Pull all orders for this cook
      final data = await SupabaseConfig.client
          .from('orders')
          .select()
          .eq('cook_id', cook.id)
          .order('created_at', ascending: false);

      // Group by customer_id → aggregate counts and dates
      final Map<String, _CustomerAgg> byCustomer = {};
      for (final row in data) {
        final customerId = (row['customer_id'] ?? '').toString();
        if (customerId.isEmpty) continue;

        final createdAt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
        final status = (row['status'] ?? '').toString();

        final agg = byCustomer.putIfAbsent(
          customerId,
          () => _CustomerAgg(
            id: customerId,
            name: (row['customer_name'] ?? 'Customer').toString(),
            phone: (row['customer_phone'] ?? '').toString(),
            address: (row['delivery_address'] ?? '').toString(),
            firstOrderAt: createdAt,
            lastOrderAt: createdAt,
          ),
        );

        agg.totalOrders++;
        if (createdAt.isBefore(agg.firstOrderAt)) agg.firstOrderAt = createdAt;
        if (createdAt.isAfter(agg.lastOrderAt)) agg.lastOrderAt = createdAt;
        // Any non-terminal order means active customer
        if (status != 'rejected' && status != 'cancelled') {
          agg.hasRecentActivity = true;
        }
      }

      final users = byCustomer.values.map((a) {
        // Active if they ordered within the last 30 days
        final isActive = a.hasRecentActivity &&
            DateTime.now().difference(a.lastOrderAt).inDays <= 30;

        return TokenUser(
          id: a.id,
          name: a.name,
          email: '', // not captured at order time
          phoneNumber: a.phone,
          address: a.address,
          profileImage: '', // no customer photo yet
          totalOrders: a.totalOrders,
          joinedDate: a.firstOrderAt,
          isActive: isActive,
        );
      }).toList();

      // Sort by total orders desc
      users.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));

      _cache = users;
      debugPrint('TokenUserService: loaded ${_cache.length} customers from orders');
      return _cache;
    } catch (e) {
      debugPrint('TokenUserService.getTokenUsers error: $e');
      return _cache;
    }
  }

  /// Get active users count (synchronous — uses cache)
  int getActiveUsersCount() {
    return _cache.where((user) => user.isActive).length;
  }

  /// Get user by ID
  Future<TokenUser?> getUserById(String id) async {
    if (_cache.isEmpty) await getTokenUsers();
    try {
      return _cache.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get total users count (synchronous — uses cache)
  int getTotalUsersCount() {
    return _cache.length;
  }
}

/// Private aggregation helper
class _CustomerAgg {
  final String id;
  final String name;
  final String phone;
  final String address;
  DateTime firstOrderAt;
  DateTime lastOrderAt;
  int totalOrders = 0;
  bool hasRecentActivity = false;

  _CustomerAgg({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.firstOrderAt,
    required this.lastOrderAt,
  });
}
