/// Enum representing different subscriber statuses
enum SubscriberStatus {
  active,
  new_,
  ready,
  done,
}

/// Enum representing subscription plan types
enum PlanType {
  monthly,
  weekly,
}

/// Enum representing meal preparation statuses
enum MealStatus {
  scheduled,
  preparing,
  packed,
  delivered,
}

/// Parse SubscriberStatus from string
SubscriberStatus subscriberStatusFromString(String s) {
  switch (s) {
    case 'new':
      return SubscriberStatus.new_;
    default:
      return SubscriberStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => SubscriberStatus.active,
      );
  }
}

/// Convert SubscriberStatus to DB string
String subscriberStatusToString(SubscriberStatus s) {
  return s == SubscriberStatus.new_ ? 'new' : s.name;
}

/// Model class representing a Subscriber
class Subscriber {
  final String id;
  final String cookId;
  final String? customerId;
  final String name;
  final String phone;
  final String profileImageUrl;
  final PlanType planType;
  final DateTime startDate;
  final DateTime endDate;
  final String todaysMeal;
  final int mealQuantity;
  final MealStatus mealStatus;
  final SubscriberStatus status;

  Subscriber({
    required this.id,
    required this.cookId,
    this.customerId,
    required this.name,
    required this.phone,
    required this.profileImageUrl,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.todaysMeal,
    required this.mealQuantity,
    required this.mealStatus,
    required this.status,
  });

  /// Create from Supabase row (snake_case)
  factory Subscriber.fromMap(Map<String, dynamic> map) {
    return Subscriber(
      id: (map['id'] ?? '').toString(),
      cookId: map['cook_id'] ?? map['cookId'] ?? '',
      customerId: map['customer_id'] ?? map['customerId'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profile_image_url'] ?? map['profileImageUrl'] ?? '',
      planType: PlanType.values.firstWhere(
        (e) => e.name == (map['plan_type'] ?? map['planType'] ?? 'monthly'),
        orElse: () => PlanType.monthly,
      ),
      startDate: DateTime.parse(
        map['start_date'] ?? map['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        map['end_date'] ?? map['endDate'] ?? DateTime.now().toIso8601String(),
      ),
      todaysMeal: map['todays_meal'] ?? map['todaysMeal'] ?? '',
      mealQuantity: map['meal_quantity'] ?? map['mealQuantity'] ?? 1,
      mealStatus: MealStatus.values.firstWhere(
        (e) => e.name == (map['meal_status'] ?? map['mealStatus'] ?? 'scheduled'),
        orElse: () => MealStatus.scheduled,
      ),
      status: subscriberStatusFromString(
        map['status'] ?? 'active',
      ),
    );
  }

  /// Convert to Supabase-compatible map (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'cook_id': cookId,
      'customer_id': customerId,
      'name': name,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'plan_type': planType.name,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'todays_meal': todaysMeal,
      'meal_quantity': mealQuantity,
      'meal_status': mealStatus.name,
      'status': subscriberStatusToString(status),
    };
  }

  /// Convert to map including ID
  Map<String, dynamic> toMapWithId() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// Create a copy with some fields updated
  Subscriber copyWith({
    String? id,
    String? cookId,
    String? customerId,
    String? name,
    String? phone,
    String? profileImageUrl,
    PlanType? planType,
    DateTime? startDate,
    DateTime? endDate,
    String? todaysMeal,
    int? mealQuantity,
    MealStatus? mealStatus,
    SubscriberStatus? status,
  }) {
    return Subscriber(
      id: id ?? this.id,
      cookId: cookId ?? this.cookId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      planType: planType ?? this.planType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      todaysMeal: todaysMeal ?? this.todaysMeal,
      mealQuantity: mealQuantity ?? this.mealQuantity,
      mealStatus: mealStatus ?? this.mealStatus,
      status: status ?? this.status,
    );
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get plan type display text
  String get planTypeText {
    switch (planType) {
      case PlanType.monthly:
        return 'Monthly Plan';
      case PlanType.weekly:
        return 'Weekly Plan';
    }
  }

  /// Get meal status display text
  String get mealStatusText {
    switch (mealStatus) {
      case MealStatus.scheduled:
        return 'SCHEDULED';
      case MealStatus.preparing:
        return 'PREPARING';
      case MealStatus.packed:
        return 'PACKED';
      case MealStatus.delivered:
        return 'DELIVERED';
    }
  }

  /// Get subscriber status display text
  String get statusText {
    switch (status) {
      case SubscriberStatus.active:
        return 'Active';
      case SubscriberStatus.new_:
        return 'New';
      case SubscriberStatus.ready:
        return 'Ready';
      case SubscriberStatus.done:
        return 'Done';
    }
  }
}
