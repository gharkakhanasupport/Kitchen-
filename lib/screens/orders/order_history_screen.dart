import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import 'order_details_screen.dart';

/// Order History Screen
/// Shows completed orders with stats and filters - Earthy, handwritten design
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _orderService = OrderService();
  final _profileService = ProfileService();

  List<Order> _completedOrders = [];
  List<Order> _cancelledOrders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  // Earthy color palette from HTML
  static const Color primaryColor = Color(0xFFb07b2b);
  static const Color statusGreen = Color(0xFF5c946e);
  static const Color statusRed = Color(0xFFcc7070);
  static const Color surfaceLight = Color(0xFFFFFDF5);
  static const Color textLight = Color(0xFF5c4033);
  static const Color accentLight = Color(0xFFe0c7a8);

  @override
  void initState() {
    super.initState();

    // Initialize background animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadOrders();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = ['All', 'Completed', 'Delivered', 'Cancelled', 'Rejected'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Orders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textLight),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) => ListTile(
                      title: Text(opt),
                      trailing: _selectedFilter == opt
                          ? const Icon(Icons.check_circle, color: primaryColor)
                          : null,
                      onTap: () {
                        setState(() => _selectedFilter = opt);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final cook = await _profileService.getCurrentProfile();
    if (cook != null) {
      final orders = await _orderService.getOrders(cook.id);

      setState(() {
        _completedOrders = orders
            .where((o) => o.status == OrderStatus.completed)
            .toList();
        _cancelledOrders = orders
            .where((o) => o.status == OrderStatus.rejected)
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Order> get _filteredOrders {
    switch (_selectedFilter) {
      case 'Delivered':
        return _completedOrders;
      case 'Cancelled':
        return _cancelledOrders;
      case 'Refunded':
        return []; // No refunded orders in current implementation
      default:
        return [..._completedOrders, ..._cancelledOrders];
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalEarnings = _completedOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF2da832),
                        const Color(0xFFc2941b),
                        _backgroundAnimation.value * 0.5,
                      )!,
                      Color.lerp(
                        const Color(0xFFc2941b),
                        const Color(0xFF2da832),
                        _backgroundAnimation.value * 0.7,
                      )!,
                      Color.lerp(
                        const Color(0xFF2da832),
                        const Color(0xFFc2941b),
                        _backgroundAnimation.value * 0.3,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating decorative circles
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                final offset = _backgroundAnimation.value * 50;
                return Positioned(
                  left: (index * 100.0) + offset,
                  top: (index * 80.0) - offset,
                  child: Opacity(
                    opacity: 0.08,
                    child: Container(
                      width: 150 + (index * 30.0),
                      height: 150 + (index * 30.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFc2941b).withValues(alpha: 0.3),
                            const Color(0xFF2da832).withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Container(
                  color: surfaceLight.withValues(alpha: 0.95),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: textLight,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'Order History',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: textLight,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.filter_list,
                                color: textLight,
                              ),
                              onPressed: _showFilterSheet,
                            ),
                          ],
                        ),
                      ),
                      Container(height: 2, color: accentLight),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 100),
                          children: [
                            const SizedBox(height: 16),

                            // Stats Cards
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Delivered',
                                      '${_completedOrders.length}',
                                      Icons.local_shipping,
                                      primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Earnings',
                                      '₹${totalEarnings.toStringAsFixed(0)}',
                                      Icons.payments,
                                      primaryColor,
                                      isEarnings: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  _buildFilterChip('All'),
                                  const SizedBox(width: 12),
                                  _buildFilterChip('Delivered'),
                                  const SizedBox(width: 12),
                                  _buildFilterChip('Cancelled'),
                                  const SizedBox(width: 12),
                                  _buildFilterChip('Refunded'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              color: accentLight,
                            ),
                            const SizedBox(height: 16),

                            // Order Cards
                            if (_filteredOrders.isEmpty)
                              _buildEmptyState()
                            else
                              ..._filteredOrders.map(
                                (order) => _buildOrderCard(order),
                              ),

                            const SizedBox(height: 32),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isEarnings = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: accentLight, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textLight.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isEarnings ? primaryColor : textLight,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : accentLight,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
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
              color: isSelected ? Colors.white : textLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: textLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textLight.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isDelivered = order.status == OrderStatus.completed;
    final statusColor = isDelivered ? statusGreen : statusRed;
    final statusText = isDelivered ? 'DELIVERED' : 'CANCELLED';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: accentLight, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(orderId: order.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        order.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(order.completedAt ?? order.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: textLight.withValues(alpha: 0.6),
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
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentLight),
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
                        color: primaryColor.withValues(alpha: 0.4),
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
                              color: textLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.items
                                .map((item) => '${item.quantity}x ${item.name}')
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: textLight.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(height: 1, color: accentLight),
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
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
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
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
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
