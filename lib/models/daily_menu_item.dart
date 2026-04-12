/// Meal category enum
enum MealCategory { special, breakfast, lunch, dinner, snacks }

/// Daily Menu Item Model
class DailyMenuItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final MealCategory category;
  final double price;
  final int quantity;
  final bool isAvailable;

  DailyMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.quantity,
    required this.isAvailable,
  });

  /// Copy with method for immutable updates
  DailyMenuItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    MealCategory? category,
    double? price,
    int? quantity,
    bool? isAvailable,
  }) {
    return DailyMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  /// Calculate total price for this item
  double get totalPrice => price * quantity;

  /// Get category display name
  String get categoryName {
    switch (category) {
      case MealCategory.special:
        return 'Today\'s Specials';
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.dinner:
        return 'Dinner';
      case MealCategory.snacks:
        return 'Snacks';
    }
  }

  /// Convert category enum to string for DB
  static String categoryToString(MealCategory cat) {
    return cat.name; // special, breakfast, lunch, dinner, snacks
  }

  /// Parse category string from DB
  static MealCategory categoryFromString(String cat) {
    return MealCategory.values.firstWhere(
      (e) => e.name == cat,
      orElse: () => MealCategory.lunch,
    );
  }

  /// Convert to Supabase-compatible map (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category': categoryToString(category),
      'price': price,
      'quantity': quantity,
      'is_available': isAvailable,
    };
  }

  /// Convert to map including ID
  Map<String, dynamic> toMapWithId() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// Create from Supabase row (snake_case keys)
  factory DailyMenuItem.fromMap(Map<String, dynamic> map) {
    return DailyMenuItem(
      id: (map['id'] ?? '').toString(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? map['imageUrl'] ?? '',
      category: categoryFromString(map['category'] ?? 'lunch'),
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      isAvailable: map['is_available'] ?? map['isAvailable'] ?? true,
    );
  }

  /// Convert to JSON (legacy format with index-based category)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.index,
      'price': price,
      'quantity': quantity,
      'isAvailable': isAvailable,
    };
  }

  /// Create from JSON (legacy format)
  factory DailyMenuItem.fromJson(Map<String, dynamic> json) {
    return DailyMenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      category: MealCategory.values[json['category']],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      isAvailable: json['isAvailable'],
    );
  }
}
