import 'daily_menu_item.dart';

/// Daily Menu Model
class DailyMenu {
  final DateTime date;
  final List<DailyMenuItem> items;

  DailyMenu({required this.date, required this.items});

  /// Get items by category
  List<DailyMenuItem> getItemsByCategory(MealCategory category) {
    return items.where((item) => item.category == category).toList();
  }

  /// Get all special items
  List<DailyMenuItem> get specials => getItemsByCategory(MealCategory.special);

  /// Get all breakfast items
  List<DailyMenuItem> get breakfastItems =>
      getItemsByCategory(MealCategory.breakfast);

  /// Get all lunch items
  List<DailyMenuItem> get lunchItems => getItemsByCategory(MealCategory.lunch);

  /// Get all dinner items
  List<DailyMenuItem> get dinnerItems =>
      getItemsByCategory(MealCategory.dinner);

  /// Get all snack items
  List<DailyMenuItem> get snackItems => getItemsByCategory(MealCategory.snacks);

  /// Calculate total potential earnings
  double get totalEarnings {
    return items
        .where((item) => item.isAvailable)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get count of available items
  int get availableItemsCount {
    return items.where((item) => item.isAvailable).length;
  }

  /// Copy with method
  DailyMenu copyWith({DateTime? date, List<DailyMenuItem>? items}) {
    return DailyMenu(date: date ?? this.date, items: items ?? this.items);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      date: DateTime.parse(json['date']),
      items: (json['items'] as List)
          .map((item) => DailyMenuItem.fromJson(item))
          .toList(),
    );
  }
}
