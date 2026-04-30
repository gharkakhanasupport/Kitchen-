import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import '../../utils/constants.dart';
import '../../models/subscriber.dart';
import '../../services/subscriber_service.dart';
import '../../widgets/otp_entry_dialog.dart';
import '../../utils/maps_launcher.dart';
import 'order_confirmation_screen.dart';
import 'order_history_screen.dart';
import '../subscribers/subscriber_details_screen.dart';

/// Orders List Screen
/// Displays orders in different tabs based on status
class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  final _orderService = OrderService();
  final _profileService = ProfileService();
  final _subscriberService = SubscriberService();

  late TabController _tabController;
  List<Order> _allOrders = [];
  List<Subscriber> _subscribers = [];
  MealStatus? _selectedMealStatus;
  bool _isLoading = true;
  bool _isOnline = true;
  String? _cookId;
  StreamSubscription? _orderStreamSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _orderStreamSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final cook = await _profileService.getCurrentProfile();
    if (cook != null) {
      _cookId = cook.id;
      final orders = await _orderService.getOrders(cook.id);
      final subscribers = await _subscriberService.getSubscribers(cook.id);

      // Listen to real-time order updates
      _orderStreamSub?.cancel();
      _orderStreamSub = _orderService.orderUpdates.listen((updatedOrders) {
        if (mounted) {
          setState(() {
            _allOrders = updatedOrders;
          });
        }
      });

      setState(() {
        _allOrders = orders;
        _subscribers = subscribers;
        _isOnline = cook.isAvailable;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Pull-to-refresh handler — forces fresh fetch from DB
  Future<void> _refreshOrders() async {
    if (_cookId == null) return;
    final orders = await _orderService.getOrders(_cookId!, forceRefresh: true);
    final subscribers = await _subscriberService.getSubscribers(_cookId!);
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _subscribers = subscribers;
      });
    }
  }

  /// Show customer contact info (call button handler)
  /// Prompt cook for 4-digit OTP shown on delivery partner's phone.
  /// Validates via Supabase RPC verify_pickup_otp; on success advances order
  /// to picked_up and refreshes list.
  Future<void> _verifyPickupOtp(Order order) async {
    final entered = await OtpEntryDialog.show(
      context,
      title: 'Verify pickup OTP',
      subtitle:
          'Ask the delivery partner for the 4-digit pickup code shown on their phone.',
    );
    if (entered == null) return;

    try {
      final result = await Supabase.instance.client.rpc(
        'verify_pickup_otp',
        params: {'p_order_id': order.id, 'p_otp': entered},
      );

      final ok = (result is Map && result['ok'] == true);
      final errorCode = (result is Map ? result['error']?.toString() : null) ?? '';

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pickup confirmed')),
        );
        if (_cookId != null) {
          _orderService.clearCache();
          final orders = await _orderService.getOrders(_cookId!);
          if (mounted) {
            setState(() => _allOrders = orders);
            _tabController.animateTo(4);
          }
        }
      } else {
        final msg = switch (errorCode) {
          'otp_mismatch' => 'Wrong OTP. Ask partner to re-read.',
          'no_otp_set' => 'No OTP generated yet for this order.',
          'already_picked_up' => 'Order already marked picked up.',
          'invalid_format' => 'OTP must be 4 digits.',
          _ => 'Verification failed ($errorCode)',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Text(
          'Cancel order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}? '
          'Customer will be refunded if paid via wallet.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await OrderService().cancelOrder(order.id);
    if (!mounted) return;
    final ok = res['ok'] == true;
    final refunded = res['refunded'] == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (refunded ? 'Order cancelled. Wallet refunded.' : 'Order cancelled.')
          : 'Failed to cancel: ${res['error'] ?? 'unknown'}'),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  Future<void> _deleteOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: const Text('This permanently removes the order from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await OrderService().deleteOrder(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Order deleted.' : 'Failed to delete order.'),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  void _showCustomerContact(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF6B7280)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.customerPhone.isEmpty ? 'No phone number' : order.customerPhone,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: order.customerPhone.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(context);
                            final ok = await MapsLauncher.call(order.customerPhone);
                            if (!ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open dialer')),
                              );
                            }
                          },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Subscriber> get _filteredSubscribers {
    if (_selectedMealStatus == null) {
      return _subscribers;
    }
    return _subscribers
        .where((s) => s.mealStatus == _selectedMealStatus)
        .toList();
  }

  List<Order> get _newOrders {
    return _allOrders.where((o) => o.status == OrderStatus.pending).toList();
  }

  List<Order> get _activeOrders {
    return _allOrders.where((o) =>
        o.status == OrderStatus.accepted || o.status == OrderStatus.preparing).toList();
  }

  List<Order> get _readyOrders {
    return _allOrders.where((o) =>
        o.status == OrderStatus.ready ||
        o.status == OrderStatus.outForDelivery).toList();
  }

  List<Order> get _doneOrders {
    return _allOrders.where((o) =>
        o.status == OrderStatus.completed || o.status == OrderStatus.delivered).toList();
  }

  List<Order> get _rejectedOrders {
    return _allOrders.where((o) => o.status == OrderStatus.rejected).toList();
  }

  Future<void> _toggleOnlineStatus() async {
    await _profileService.toggleAvailability();
    setState(() {
      _isOnline = !_isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Live Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111814),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF111814)),
          tooltip: 'Refresh orders',
          onPressed: _refreshOrders,
        ),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Orders Help'),
                  content: const Text(
                    'Tabs:\n\n'
                    '• Subscribers — your meal subscribers\n'
                    '• New — pending orders waiting for your acceptance\n'
                    '• Active — accepted and preparing orders\n'
                    '• Ready — orders ready for pickup/delivery\n'
                    '• Done — completed orders\n\n'
                    'Pull down on any list to refresh.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Help',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF618971),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              isScrollable: true,
              tabs: [
                const Tab(text: 'Subscribers'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('New'),
                      if (_newOrders.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_newOrders.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Active'),
                      if (_activeOrders.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_activeOrders.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Ready'),
                const Tab(text: 'Done'),
                const Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kitchen Status Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kitchen Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111814),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isOnline
                                  ? 'You are currently accepting new orders'
                                  : 'You are not accepting new orders',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF618971),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOnline,
                        onChanged: (value) => _toggleOnlineStatus(),
                        activeThumbColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubscribersList(),
                      _buildOrdersList(_newOrders, 'New'),
                      _buildOrdersList(_activeOrders, 'Preparing'),
                      _buildOrdersList(_readyOrders, 'Ready'),
                      _buildOrdersList(_doneOrders, 'Done'),
                      _buildOrdersList(_rejectedOrders, 'Rejected'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, String type) {
    if (type == 'Done') {
      return _buildHistoryView(orders);
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.soup_kitchen,
                    size: 64,
                    color: const Color(0xFF618971).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == 'Ready'
                        ? 'No orders ready for pickup'
                        : 'You\'re all caught up for now!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF618971).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF618971).withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter chips for Ready tab
        if (type == 'Ready')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Orders', Icons.check_circle, true),
                  const SizedBox(width: 12),
                  _buildFilterChip('Paid', Icons.credit_card, false),
                  const SizedBox(width: 12),
                  _buildFilterChip('Cash on Delivery', Icons.payments, false),
                ],
              ),
            ),
          ),

        // Orders list
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshOrders,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: orders.length + (type != 'Ready' ? 1 : 0),
            itemBuilder: (context, index) {
              if (type != 'Ready' && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == 'Preparing'
                            ? 'In Progress (${orders.length})'
                            : type == 'New'
                            ? 'New Requests (${orders.length})'
                            : '$type Orders (${orders.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111814),
                        ),
                      ),
                      if (type == 'Preparing')
                        const Text(
                          'KITCHEN QUEUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF618971),
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                );
              }

              final order = orders[type != 'Ready' ? index - 1 : index];
              return type == 'Preparing'
                  ? _buildPreparingOrderCard(order)
                  : type == 'New'
                  ? _buildNewOrderCard(order)
                  : type == 'Ready'
                  ? _buildReadyOrderCard(order)
                  : _buildCompletedOrderCard(order);
            },
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isActive) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? AppColors.primary : const Color(0xFFE5E7EB),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparingOrderCard(Order order) {
    final elapsed = DateTime.now().difference(order.createdAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111814),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111814),
                          ),
                        ),
                        Text(
                          '${order.id} • Paid • ₹${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF618971),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat,
                        size: 18,
                        color: Color(0xFF618971),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call,
                        size: 18,
                        color: Color(0xFF618971),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111814),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Footer
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.timer,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Elapsed Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF618971),
                                ),
                              ),
                              Text(
                                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF111814),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.status == OrderStatus.accepted ? 'Accepted' : 'Preparing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: order.status == OrderStatus.accepted ? Colors.blue : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (order.status == OrderStatus.accepted)
                  Container(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _orderService.updateOrderStatus(
                          order.id,
                          OrderStatus.preparing,
                        );
                        if (_cookId != null) {
                          _orderService.clearCache();
                          final orders = await _orderService.getOrders(_cookId!);
                          if (mounted) setState(() => _allOrders = orders);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.restaurant, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Start Preparing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.secondary, const Color(0xFF228526)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _orderService.updateOrderStatus(
                        order.id,
                        OrderStatus.ready,
                      );
                      if (_cookId != null) {
                        _orderService.clearCache();
                        final orders = await _orderService.getOrders(_cookId!);
                        if (mounted) {
                          setState(() => _allOrders = orders);
                          _tabController.animateTo(3); // Move to Ready tab
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mark Ready for Pickup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrderCard(Order order) {
    final timeAgo = DateTime.now().difference(order.createdAt);
    final minutes = timeAgo.inMinutes;
    final isUrgent = minutes >= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUrgent
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF6F8F7),
              border: Border(
                bottom: BorderSide(
                  color: isUrgent
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isUrgent
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF64748b),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      minutes == 0 ? 'JUST NOW' : 'RECEIVED $minutes MINS AGO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isUrgent
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF64748b),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  order.id,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer name and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0f172a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Paid Online',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748b),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Items
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                              ),
                              children: [
                                TextSpan(
                                  text: '${item.quantity}x ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: item.name),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Special note
                      if (order.deliveryAddress.toLowerCase().contains(
                            'spicy',
                          ) ||
                          order.deliveryAddress.toLowerCase().contains('note'))
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.sticky_note_2,
                                size: 14,
                                color: Color(0xFFF97316),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '"${order.deliveryAddress}"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9a3412),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Right side - Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: AppColors.secondary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        await _orderService.rejectOrder(order.id);
                        _loadOrders();
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF64748b),
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748b),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        // Show confirmation screen first
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderConfirmationScreen(order: order),
                          ),
                        );

                        // Accept the order
                        await _orderService.acceptOrder(order.id);
                        // Refresh from DB to ensure latest state
                        if (_cookId != null) {
                          _orderService.clearCache();
                          final orders = await _orderService.getOrders(_cookId!);
                          if (mounted) setState(() => _allOrders = orders);
                        }

                        // Switch to Active tab after accepting
                        if (mounted) {
                          _tabController.animateTo(2); // Index 2 is Active tab
                        }
                      },
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Accept Order',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyOrderCard(Order order) {
    final readyTime = order.acceptedAt ?? order.createdAt;
    final timeString =
        '${readyTime.hour}:${readyTime.minute.toString().padLeft(2, '0')} ${readyTime.hour >= 12 ? 'PM' : 'AM'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left accent
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.id,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111814),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'READY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ready since $timeString',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.call,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          tooltip: 'Call customer',
                          onPressed: () => _showCustomerContact(order),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      // Food Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Order Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              order.items
                                  .map(
                                    (item) => '${item.quantity}x ${item.name}',
                                  )
                                  .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '₹${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111814),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '• Paid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Verify Pickup OTP button (only when status=ready) OR
                // "Out for Delivery" chip (when partner already picked up).
                if (order.status == OrderStatus.outForDelivery)
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF618971).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF618971).withValues(alpha: 0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining, color: Color(0xFF618971), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Out for Delivery',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF618971),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton.icon(
                      onPressed: () => _verifyPickupOtp(order),
                      icon: const Icon(
                        Icons.lock_open,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Verify Pickup OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (order.status != OrderStatus.outForDelivery)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelOrder(order),
                    icon: Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                    label: Text('Cancel Order',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade700),
                  onPressed: () => _deleteOrder(order),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111814),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111814),
                  ),
                ),
                Text(
                  '${order.id} • ₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF618971),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            order.status == OrderStatus.rejected
                ? Icons.cancel
                : Icons.check_circle,
            color: order.status == OrderStatus.rejected
                ? Colors.red
                : AppColors.primary,
            size: 24,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 20),
            onPressed: () => _deleteOrder(order),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersList() {
    return Column(
      children: [
        // Meal Status Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMealFilterChip('All', null, Colors.grey.shade700),
                const SizedBox(width: 8),
                _buildMealFilterChip(
                  'Scheduled',
                  MealStatus.scheduled,
                  Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                _buildMealFilterChip(
                  'Preparing',
                  MealStatus.preparing,
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildMealFilterChip(
                  'Packed',
                  MealStatus.packed,
                  AppColors.secondary,
                ),
                const SizedBox(width: 8),
                _buildMealFilterChip(
                  'Delivered',
                  MealStatus.delivered,
                  AppColors.success,
                ),
              ],
            ),
          ),
        ),

        // Subscribers list
        Expanded(
          child: _filteredSubscribers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: const Color(0xFF618971).withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subscribers found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF618971).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredSubscribers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subscribers (${_filteredSubscribers.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111814),
                              ),
                            ),
                            const Text(
                              'SUBSCRIPTION PLANS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF618971),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final subscriber = _filteredSubscribers[index - 1];
                    return _buildSubscriberCard(subscriber);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMealFilterChip(String label, MealStatus? status, Color color) {
    final isSelected = _selectedMealStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealStatus = status;
        });
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriberCard(Subscriber subscriber) {
    // Get background color based on plan type
    final backgroundColor = subscriber.planType == PlanType.monthly
        ? const Color(0xFF8C6A13) // Gold dark
        : const Color(0xFF1F7A23); // Green dark

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SubscriberDetailsScreen(subscriber: subscriber),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                    width: 4,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(subscriber.profileImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Subscriber details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and plan type
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subscriber.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            subscriber.planTypeText.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Days remaining
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ends in ${subscriber.daysRemaining} days',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Today's meal card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TODAY\'S MEAL',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${subscriber.mealQuantity}x ${subscriber.todaysMeal}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getMealStatusColor(subscriber.mealStatus),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subscriber.mealStatusText,
                              style: TextStyle(
                                color: _getMealStatusTextColor(
                                  subscriber.mealStatus,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealStatusColor(MealStatus status) {
    switch (status) {
      case MealStatus.preparing:
        return AppColors.primary;
      case MealStatus.scheduled:
        return Colors.white.withValues(alpha: 0.2);
      case MealStatus.packed:
        return AppColors.secondary.withValues(alpha: 0.2);
      case MealStatus.delivered:
        return AppColors.success;
    }
  }

  Color _getMealStatusTextColor(MealStatus status) {
    switch (status) {
      case MealStatus.preparing:
        return AppColors.primary;
      case MealStatus.scheduled:
        return Colors.black87;
      case MealStatus.packed:
        return AppColors.secondary;
      case MealStatus.delivered:
        return Colors.white;
    }
  }

  Widget _buildHistoryView(List<Order> orders) {
    final totalEarnings = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // View All History Button
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFb07b2b), Color(0xFFa07a16)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFb07b2b).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.history, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'View All Order History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),

        // Stats Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 24,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total Delivered',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${orders.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111814),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments,
                          size: 24,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total Earnings',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalEarnings.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildHistoryFilterChip('All', true),
              const SizedBox(width: 12),
              _buildHistoryFilterChip('Delivered', false),
              const SizedBox(width: 12),
              _buildHistoryFilterChip('Cancelled', false),
              const SizedBox(width: 12),
              _buildHistoryFilterChip('Refunded', false),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(height: 1, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 16),

        // Order History Cards
        if (orders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: const Color(0xFF618971).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No order history yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF618971).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...orders.map((order) => _buildHistoryOrderCard(order)),
      ],
    );
  }

  Widget _buildHistoryFilterChip(String label, bool isActive) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondary : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    order.id,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                Text(
                  _formatHistoryDate(order.completedAt ?? order.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Row(
              children: [
                // Food Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 16),

                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111814),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.items
                            .map((item) => '${item.quantity}x ${item.name}')
                            .join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111814),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(height: 1, color: const Color(0xFFE5E7EB)),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DELIVERED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatHistoryDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
