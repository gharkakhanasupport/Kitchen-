import 'package:flutter/material.dart';
import '../../models/subscriber.dart';
import '../../utils/constants.dart';

/// Subscriber Details Screen
/// Beautiful dark luxury design for viewing subscriber profile
class SubscriberDetailsScreen extends StatelessWidget {
  final Subscriber subscriber;

  const SubscriberDetailsScreen({super.key, required this.subscriber});

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
                  _buildMealCalendar(),
                  _buildSubscriptionHistory(),
                  const SizedBox(height: 80), // Bottom padding for nav
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
                'Subscriber Profile',
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
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: NetworkImage(subscriber.profileImageUrl),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1C2A20),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            subscriber.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0E7E1),
            ),
          ),

          const SizedBox(height: 8),

          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.location_on,
                size: 16,
                color: Color(0xFF9BA69F), // text-muted-luxury
              ),
              SizedBox(width: 4),
              Text(
                'Vasant Kunj, New Delhi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9BA69F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat, size: 20),
                  label: const Text(
                    'Chat',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.edit_calendar,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Modify Plan',
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
              'Duration',
              '${subscriber.daysRemaining ~/ 30} Mo',
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Status',
              'Active',
              const Color(0xFFA8C0A8), // status-active
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard('Total', '\$184', const Color(0xFFE0E7E1)),
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
            label.toUpperCase(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Dietary Preferences',
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

  Widget _buildMealCalendar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meal Calendar',
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

          // Today's Meal Card
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
                    Icons.restaurant,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LUNCH • 12:30 PM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9BA69F),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscriber.todaysMeal,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0E7E1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+ ${subscriber.mealQuantity} Servings',
                        style: const TextStyle(
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
    bool hasMeal,
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
              color: hasMeal
                  ? (isToday ? Colors.white : const Color(0xFFA8C0A8))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistory() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0E7E1),
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            'Monthly Plan Renewed',
            'September 1st, 2023',
            '\$45.00',
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'Monthly Plan Renewed',
            'August 1st, 2023',
            '\$45.00',
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'View All History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9BA69F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3B30),
        borderRadius: BorderRadius.circular(16),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFA8C0A8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt,
              size: 20,
              color: Color(0xFFA8C0A8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0E7E1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9BA69F),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0E7E1),
            ),
          ),
        ],
      ),
    );
  }
}
