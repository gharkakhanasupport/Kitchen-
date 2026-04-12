import 'package:flutter/material.dart';
import '../../models/subscriber.dart';
import '../../services/subscriber_service.dart';
import '../../utils/constants.dart';
import 'subscriber_card.dart';
import 'subscriber_details_screen.dart';

/// Subscribers Management Screen
/// Displays and manages subscription-based customers
class SubscribersScreen extends StatefulWidget {
  const SubscribersScreen({super.key});

  @override
  State<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends State<SubscribersScreen>
    with SingleTickerProviderStateMixin {
  final _subscriberService = SubscriberService();
  late TabController _tabController;

  List<Subscriber> _subscribers = [];
  int _activeCount = 0;
  bool _isLoading = true;
  MealStatus? _selectedMealStatus; // Filter for meal status

  // Hardcoded cook ID for demo purposes
  final String _cookId = 'cook_123';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Reset meal status filter when changing tabs
      setState(() {
        _selectedMealStatus = null;
      });
      _loadSubscribersByTab();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load active count
    final count = await _subscriberService.getActiveSubscribersCount(_cookId);

    // Load subscribers based on current tab
    await _loadSubscribersByTab();

    setState(() {
      _activeCount = count;
      _isLoading = false;
    });
  }

  Future<void> _loadSubscribersByTab() async {
    List<Subscriber> subscribers;

    switch (_tabController.index) {
      case 0: // Subscription - with meal status filter
        subscribers = await _subscriberService.getSubscribers(_cookId);
        // Filter by meal status if selected
        if (_selectedMealStatus != null) {
          subscribers = subscribers
              .where((s) => s.mealStatus == _selectedMealStatus)
              .toList();
        }
        break;
      case 1: // New
        subscribers = await _subscriberService.getSubscribersByStatus(
          _cookId,
          SubscriberStatus.new_,
        );
        break;
      case 2: // Ready
        subscribers = await _subscriberService.getSubscribersByStatus(
          _cookId,
          SubscriberStatus.ready,
        );
        break;
      case 3: // Done
        subscribers = await _subscriberService.getSubscribersByStatus(
          _cookId,
          SubscriberStatus.done,
        );
        break;
      default:
        subscribers = await _subscriberService.getSubscribers(_cookId);
    }

    setState(() => _subscribers = subscribers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(child: Center(child: Text('Menu Placeholder'))),
      backgroundColor: const Color(0xFFF6F8F7),
      body: Column(
        children: [
          // App Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Subscribers',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Help'),
                                content: const Text(
                                  'This screen manages your subscribers.\n\n'
                                  '• New: New subscription requests\n'
                                  '• Ready: Meals ready for pickup/delivery\n'
                                  '• Done: Completed orders\n\n'
                                  'Tap on a subscriber to view details.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            'Help',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.secondary,
                    indicatorWeight: 3,
                    labelColor: AppColors.secondary,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Subscription'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('New'),
                            SizedBox(width: 4),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(text: 'Ready'),
                      Tab(text: 'Done'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          // Stats Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFc2941b), // Primary gold
                                  Color(0xFF8C6A13), // Gold dark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Decorative circles
                                Positioned(
                                  bottom: -12,
                                  right: -12,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -16,
                                  left: -16,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),

                                // Content
                                Column(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 60,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      '$_activeCount',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'ACTIVE SUBSCRIBERS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Meal Status Filter Chips (only show on Subscription tab)
                          if (_tabController.index == 0) ...[
                            Row(
                              children: [
                                const Text(
                                  'Filter by Status:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          null,
                                          Colors.grey.shade700,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        _buildFilterChip(
                                          'Scheduled',
                                          MealStatus.scheduled,
                                          Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        _buildFilterChip(
                                          'Preparing',
                                          MealStatus.preparing,
                                          AppColors.primary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        _buildFilterChip(
                                          'Packed',
                                          MealStatus.packed,
                                          AppColors.secondary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        _buildFilterChip(
                                          'Delivered',
                                          MealStatus.delivered,
                                          AppColors.success,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Subscriber List Header
                          if (_subscribers.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Roster (${_subscribers.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'PREMIUM PLANS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Subscriber Cards
                            ..._subscribers.map(
                              (subscriber) => SubscriberCard(
                                subscriber: subscriber,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SubscriberDetailsScreen(
                                            subscriber: subscriber,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Empty State
                          if (_subscribers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xxl,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_pin,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'No more subscribers to show',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip for meal status
  Widget _buildFilterChip(String label, MealStatus? status, Color color) {
    final isSelected = _selectedMealStatus == status;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMealStatus = status;
        });
        _loadSubscribersByTab();
      },
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.3),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
