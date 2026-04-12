import 'package:flutter/material.dart';
import '../../models/subscriber.dart';
import '../../utils/constants.dart';

/// Subscriber Card Widget
/// Displays subscriber information with color-coded design based on plan type
class SubscriberCard extends StatelessWidget {
  final Subscriber subscriber;
  final VoidCallback? onTap;

  const SubscriberCard({super.key, required this.subscriber, this.onTap});

  /// Get background color based on plan type
  Color get _backgroundColor {
    switch (subscriber.planType) {
      case PlanType.monthly:
        return const Color(0xFF8C6A13); // Gold dark
      case PlanType.weekly:
        return const Color(0xFF1F7A23); // Green dark
    }
  }

  /// Get ring color based on plan type
  Color get _ringColor {
    switch (subscriber.planType) {
      case PlanType.monthly:
        return AppColors.secondary; // Gold
      case PlanType.weekly:
        return AppColors.primary; // Green
    }
  }

  /// Get meal status badge color
  Color _getMealStatusColor() {
    switch (subscriber.mealStatus) {
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

  /// Get meal status text color
  Color _getMealStatusTextColor() {
    switch (subscriber.mealStatus) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                // Chevron icon
                const Positioned(
                  right: 16,
                  top: 16,
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile image with status indicator
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _ringColor.withValues(alpha: 0.5),
                                width: 4,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(subscriber.profileImageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _backgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),

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
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.full,
                                    ),
                                  ),
                                  child: Text(
                                    subscriber.planTypeText.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),

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
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Today's meal card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TODAY\'S MEAL',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: Colors.white60,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                                letterSpacing: 0.8,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${subscriber.mealQuantity}x ${subscriber.todaysMeal}',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMealStatusColor(),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                    child: Text(
                                      subscriber.mealStatusText,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: _getMealStatusTextColor(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
