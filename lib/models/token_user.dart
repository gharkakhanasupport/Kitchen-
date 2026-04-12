/// Token User Model
/// Represents a regular user (not a subscriber)
class TokenUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final String profileImage;
  final int totalOrders;
  final DateTime joinedDate;
  final bool isActive;

  TokenUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.profileImage,
    required this.totalOrders,
    required this.joinedDate,
    required this.isActive,
  });

  /// Copy with method
  TokenUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? profileImage,
    int? totalOrders,
    DateTime? joinedDate,
    bool? isActive,
  }) {
    return TokenUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      totalOrders: totalOrders ?? this.totalOrders,
      joinedDate: joinedDate ?? this.joinedDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImage': profileImage,
      'totalOrders': totalOrders,
      'joinedDate': joinedDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create from JSON
  factory TokenUser.fromJson(Map<String, dynamic> json) {
    return TokenUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      profileImage: json['profileImage'],
      totalOrders: json['totalOrders'],
      joinedDate: DateTime.parse(json['joinedDate']),
      isActive: json['isActive'],
    );
  }
}
