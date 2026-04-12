import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../menu/daily_menu_management_screen.dart';
import '../orders/orders_list_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/view_profile_screen.dart';
import '../users/token_users_screen.dart';
import '../../services/profile_service.dart';
import '../../services/order_service.dart';
import '../../services/menu_service.dart';
import '../../services/earnings_service.dart';
import '../../models/cook.dart';

/// Home Screen
/// Main dashboard with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _profileService = ProfileService();
  final _orderService = OrderService();
  final _menuService = MenuService();

  Cook? _cook;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });

    _cook = await _profileService.getCurrentProfile();

    if (_cook == null) {
      // Try refreshing from Supabase instead of loading sample data
      _cook = await _profileService.refreshProfile();
    }

    if (_cook != null) {
      // Load real data from Supabase (no more sample data)
      await _menuService.getMenuItems(_cook!.id);
      await _orderService.getOrders(_cook!.id);

      // Start real-time listener for incoming orders
      _orderService.startRealtimeListener(_cook!.id);

      // Sync profile to kitchens table
      await _profileService.refreshProfile();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      _DashboardTab(cook: _cook),
      const DailyMenuManagementScreen(),
      const OrdersListScreen(),
      const WalletScreen(),
      const ViewProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Dashboard Tab - Home overview with kitchen status
class _DashboardTab extends StatefulWidget {
  final Cook? cook;

  const _DashboardTab({this.cook});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _orderService = OrderService();
  final _menuService = MenuService();
  final _earningsService = EarningsService();
  final _profileService = ProfileService();

  int _pendingOrdersCount = 0;
  int _activeOrdersCount = 0;
  int _menuItemsCount = 0;
  double _todayEarnings = 0.0;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (widget.cook == null) return;

    final pendingOrders = await _orderService.getPendingOrders(widget.cook!.id);
    final activeOrders = await _orderService.getActiveOrders(widget.cook!.id);
    final menuItems = await _menuService.getMenuItems(widget.cook!.id);
    final earnings = await _earningsService.getTodayEarnings(widget.cook!.id);

    setState(() {
      _pendingOrdersCount = pendingOrders.length;
      _activeOrdersCount = activeOrders.length;
      _menuItemsCount = menuItems.length;
      _todayEarnings = earnings.totalRevenue;
      _isOnline = widget.cook?.isAvailable ?? true;
    });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghar Ka Khana',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            if (widget.cook != null)
              Text(
                widget.cook!.kitchenName,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748b)),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kitchen Status Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with gradient
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Column(
                        children: [
                          // Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  const Color(0xFF238527),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            _isOnline ? 'You are Online' : 'You are Offline',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _isOnline
                                  ? 'Your kitchen is visible to customers'
                                  : 'Your kitchen is hidden from customers',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748b),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status Badge
                          if (_isOnline)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
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
                                    'ACCEPTING ORDERS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kitchen Status',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1e293b),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Toggle to go offline',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF94a3b8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isOnline,
                                    onChanged: (value) => _toggleOnlineStatus(),
                                    activeThumbColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Token Users Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TokenUsersScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Token Users',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View all regular users',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Warning Note for Active Orders
              if (_activeOrdersCount > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: AppColors.secondary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Note: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const TextSpan(text: 'You have '),
                              TextSpan(
                                text:
                                    '$_activeOrdersCount active ${_activeOrdersCount == 1 ? 'order' : 'orders'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    '. Fulfill them before closing to avoid penalties.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_activeOrdersCount > 0) const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending Orders',
                      _pendingOrdersCount.toString(),
                      Icons.pending_actions,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Orders',
                      _activeOrdersCount.toString(),
                      Icons.local_shipping,
                      AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Menu Items',
                      _menuItemsCount.toString(),
                      Icons.restaurant_menu,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Today Earnings',
                      '₹${_todayEarnings.toStringAsFixed(0)}',
                      Icons.currency_rupee,
                      AppColors.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                'View Pending Orders',
                'Check and accept new orders',
                Icons.notifications_active,
                AppColors.warning,
                () {
                  final homeState = context
                      .findAncestorStateOfType<_HomeScreenState>();
                  homeState?.setState(() {
                    homeState._currentIndex = 2;
                  });
                },
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                'Add Menu Item',
                'Add new dishes to your menu',
                Icons.add_circle,
                AppColors.success,
                () {
                  final homeState = context
                      .findAncestorStateOfType<_HomeScreenState>();
                  homeState?.setState(() {
                    homeState._currentIndex = 1;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF94a3b8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
