/// Model class representing a Menu Item
/// This stores information about food items that cooks want to sell
class MenuItem {
  final String id;
  final String cookId;
  final String name;
  final String description;
  final double price;
  final int quantityAvailable;
  final String category; // e.g., "Breakfast", "Lunch", "Dinner", "Snacks"
  final List<String> imageUrls;
  final bool isAvailable;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.cookId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantityAvailable,
    required this.category,
    this.imageUrls = const [],
    this.isAvailable = true,
    required this.createdAt,
  });

  /// Get the primary image for display
  String? get displayImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Create a MenuItem from Supabase row (snake_case keys)
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    List<String> images = [];
    if (map['image_urls'] is List) {
      images = List<String>.from(map['image_urls']);
    } else if (map['image_url'] != null) {
      images = [map['image_url'].toString()];
    }

    return MenuItem(
      id: (map['id'] ?? '').toString(),
      cookId: map['cook_id'] ?? map['cookId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantityAvailable: map['quantity_available'] ?? map['quantityAvailable'] ?? 0,
      category: map['category'] ?? '',
      imageUrls: images,
      isAvailable: map['is_available'] ?? map['isAvailable'] ?? true,
      createdAt: DateTime.parse(
        map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to Supabase-compatible map (snake_case keys)
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = {
      'cook_id': cookId,
      'name': name,
      'description': description,
      'price': price,
      'quantity_available': quantityAvailable,
      'category': category,
      'image_urls': imageUrls,
      'image_url': displayImage, // Legacy support
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };

    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  /// Map for initial insertion (no ID, let DB generate it)
  Map<String, dynamic> toInsertMap() {
    return toMap(includeId: false);
  }

  /// Convert to map including ID (for upserts)
  Map<String, dynamic> toMapWithId() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// Create a copy of MenuItem with some fields updated
  MenuItem copyWith({
    String? id,
    String? cookId,
    String? name,
    String? description,
    double? price,
    int? quantityAvailable,
    String? category,
    List<String>? imageUrls,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      cookId: cookId ?? this.cookId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
