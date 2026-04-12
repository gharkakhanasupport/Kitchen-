/// Model class representing a Cook/Kitchen profile
/// This stores all the information about the home cook and their kitchen
class Cook {
  final String id;
  final String phoneNumber;
  final String email;
  final String kitchenName;
  final String ownerName;
  final String address;
  final String specialty; // e.g., "North Indian", "South Indian", "Chinese"
  final String gender;
  final String? profileImageUrl;
  final bool isAvailable; // Online/Offline status
  final bool isVegetarian;
  final List<String> kitchenPhotos;
  final DateTime createdAt;
  final double rating;
  final int totalOrders;
  final int earnings;

  Cook({
    required this.id,
    required this.phoneNumber,
    required this.email,
    required this.kitchenName,
    required this.ownerName,
    required this.address,
    required this.specialty,
    this.gender = 'Not specified',
    this.profileImageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.kitchenPhotos = const [],
    required this.createdAt,
    this.rating = 4.8,
    this.totalOrders = 150,
    this.earnings = 1240,
  });

  /// Create a Cook object from a Map (useful for JSON parsing)
  factory Cook.fromMap(Map<String, dynamic> map) {
    return Cook(
      id: (map['id'] ?? map['phone'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      kitchenName: (map['kitchenName'] ?? map['kitchen_name'] ?? 'My Kitchen').toString(),
      ownerName: (map['ownerName'] ?? map['full_name'] ?? 'Chef').toString(),
      address: (map['address'] ?? map['location'] ?? '').toString(),
      specialty: (map['specialty'] ?? map['kitchen_description'] ?? 'Home Cook').toString(),
      gender: (map['gender'] ?? 'Not specified').toString(),
      profileImageUrl: map['profile_image_url'] ?? map['profileImageUrl'] ?? (map['kitchen_photos'] != null && (map['kitchen_photos'] as List).isNotEmpty ? (map['kitchen_photos'] as List).first : null),
      isAvailable: map['isAvailable'] ?? map['is_available'] ?? map['is_online'] ?? true,
      isVegetarian: map['isVegetarian'] ?? map['is_vegetarian'] ?? false,
      kitchenPhotos: map['kitchen_photos'] != null ? List<String>.from(map['kitchen_photos']) : const [],
      createdAt: DateTime.parse(
        map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      rating: (map['rating'] ?? 4.8).toDouble(),
      totalOrders: map['totalOrders'] ?? 150,
      earnings: map['earnings'] ?? 1240,
    );
  }

  /// Convert Cook object to Map (useful for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'kitchenName': kitchenName,
      'ownerName': ownerName,
      'address': address,
      'specialty': specialty,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'kitchenPhotos': kitchenPhotos,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'totalOrders': totalOrders,
      'earnings': earnings,
    };
  }

  /// Create a copy of Cook with some fields updated
  Cook copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? kitchenName,
    String? ownerName,
    String? address,
    String? specialty,
    String? gender,
    String? profileImageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    List<String>? kitchenPhotos,
    DateTime? createdAt,
    double? rating,
    int? totalOrders,
    int? earnings,
  }) {
    return Cook(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      kitchenName: kitchenName ?? this.kitchenName,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      specialty: specialty ?? this.specialty,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      kitchenPhotos: kitchenPhotos ?? this.kitchenPhotos,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      earnings: earnings ?? this.earnings,
    );
  }
}
