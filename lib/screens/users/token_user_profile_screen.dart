import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/token_user.dart';
import '../../utils/constants.dart';

/// Token User Profile Screen
/// Beautiful dark luxury design matching subscriber profile exactly
class TokenUserProfileScreen extends StatelessWidget {
  final TokenUser user;

  const TokenUserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2A20), // background-luxury
      body: Column(
        children: [
          // Header
          _buildHeader(context),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileSection(),
                  _buildStatsGrid(),
                  _buildDietaryPreferences(),
                  _buildOrderCalendar(),
                  _buildOrderHistory(),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A20).withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF405245), // border-luxury
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFFE0E7E1), // text-light
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2A3B30), // surface-luxury
                  shape: const CircleBorder(),
                ),
              ),
              const Text(
                'User Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E7E1),
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: Color(0xFFE0E7E1)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2A3B30),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              // Glow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Profile image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: DecorationImage(
                    image: NetworkImage(user.profileImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Active badge
              if (user.isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1C2A20),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0E7E1),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            user.email,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9BA8A0)),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text(
                    'Call',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.message, size: 20, color: AppColors.primary),
                  label: Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A3B30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF405245)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'ORDERS',
              '${user.totalOrders}',
              const Color(0xFFE0E7E1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'STATUS',
              user.isActive ? 'Active' : 'Inactive',
              user.isActive ? const Color(0xFFA8C0A8) : const Color(0xFF9BA8A0),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'JOINED',
              DateFormat('MMM yy').format(user.joinedDate),
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3B30), // surface-luxury
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF405245), // border-luxury
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9BA69F),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryPreferences() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Food Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E7E1),
                ),
              ),
              Icon(Icons.restaurant, color: Color(0xFF9BA69F)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPreferenceChip(
                'Vegetarian',
                Icons.eco,
                const Color(0xFF4ADE80),
                const Color(0xFF14532D),
              ),
              _buildPreferenceChip(
                'Low Spice',
                Icons.local_fire_department_outlined,
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.1),
              ),
              _buildPreferenceChip(
                'High Protein',
                Icons.fitness_center,
                const Color(0xFF60A5FA),
                const Color(0xFF1E3A8A),
              ),
              _buildPreferenceChip(
                'No Peanuts',
                Icons.cancel,
                const Color(0xFFF87171),
                const Color(0xFF7F1D1D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChip(
    String label,
    IconData icon,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCalendar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E7E1),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Full View',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar Days
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCalendarDay('Today', '18', true, true),
                const SizedBox(width: 12),
                _buildCalendarDay('Thu', '19', false, true),
                const SizedBox(width: 12),
                _buildCalendarDay('Fri', '20', false, true),
                const SizedBox(width: 12),
                _buildCalendarDay('Sat', '21', false, false),
                const SizedBox(width: 12),
                _buildCalendarDay('Sun', '22', false, false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent Order Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3B30),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF405245)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF405245),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAST ORDER • 2 DAYS AGO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9BA69F),
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Butter Chicken Combo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0E7E1),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '+ 2 Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9BA69F),
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
    );
  }

  Widget _buildCalendarDay(
    String day,
    String date,
    bool isToday,
    bool hasOrder,
  ) {
    return Container(
      width: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary : const Color(0xFF2A3B30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppColors.primary : const Color(0xFF405245),
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            day.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.8)
                  : const Color(0xFF9BA69F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : const Color(0xFFE0E7E1),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: hasOrder
                  ? (isToday ? Colors.white : const Color(0xFFA8C0A8))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistory() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0E7E1),
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            'Order Delivered',
            'December 15th, 2023',
            '₹450',
            Icons.check_circle,
            const Color(0xFFA8C0A8),
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'Order Delivered',
            'December 12th, 2023',
            '₹320',
            Icons.check_circle,
            const Color(0xFFA8C0A8),
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'Order Delivered',
            'December 8th, 2023',
            '₹680',
            Icons.check_circle,
            const Color(0xFFA8C0A8),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String title,
    String date,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3B30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF405245)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0E7E1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9BA69F),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
