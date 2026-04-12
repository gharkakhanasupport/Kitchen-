import '../models/token_user.dart';

/// Token User Service
/// Manages regular user data
class TokenUserService {
  // Demo users
  final List<TokenUser> _demoUsers = [
    TokenUser(
      id: 'user_001',
      name: 'Rajesh Kumar',
      email: 'rajesh.kumar@example.com',
      phoneNumber: '+91 98765 43210',
      address: '123 MG Road, Bangalore, Karnataka 560001',
      profileImage:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      totalOrders: 45,
      joinedDate: DateTime(2023, 6, 15),
      isActive: true,
    ),
    TokenUser(
      id: 'user_002',
      name: 'Priya Sharma',
      email: 'priya.sharma@example.com',
      phoneNumber: '+91 98765 43211',
      address: '456 Brigade Road, Bangalore, Karnataka 560025',
      profileImage:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      totalOrders: 32,
      joinedDate: DateTime(2023, 7, 20),
      isActive: true,
    ),
    TokenUser(
      id: 'user_003',
      name: 'Amit Patel',
      email: 'amit.patel@example.com',
      phoneNumber: '+91 98765 43212',
      address: '789 Indiranagar, Bangalore, Karnataka 560038',
      profileImage:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      totalOrders: 28,
      joinedDate: DateTime(2023, 8, 10),
      isActive: true,
    ),
    TokenUser(
      id: 'user_004',
      name: 'Sneha Reddy',
      email: 'sneha.reddy@example.com',
      phoneNumber: '+91 98765 43213',
      address: '321 Koramangala, Bangalore, Karnataka 560034',
      profileImage:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      totalOrders: 51,
      joinedDate: DateTime(2023, 5, 5),
      isActive: true,
    ),
    TokenUser(
      id: 'user_005',
      name: 'Vikram Singh',
      email: 'vikram.singh@example.com',
      phoneNumber: '+91 98765 43214',
      address: '654 Whitefield, Bangalore, Karnataka 560066',
      profileImage:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      totalOrders: 19,
      joinedDate: DateTime(2023, 9, 12),
      isActive: false,
    ),
    TokenUser(
      id: 'user_006',
      name: 'Ananya Iyer',
      email: 'ananya.iyer@example.com',
      phoneNumber: '+91 98765 43215',
      address: '987 Jayanagar, Bangalore, Karnataka 560041',
      profileImage:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      totalOrders: 37,
      joinedDate: DateTime(2023, 7, 8),
      isActive: true,
    ),
  ];

  /// Get all token users
  Future<List<TokenUser>> getTokenUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _demoUsers;
  }

  /// Get active users count
  int getActiveUsersCount() {
    return _demoUsers.where((user) => user.isActive).length;
  }

  /// Get user by ID
  Future<TokenUser?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _demoUsers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get total users count
  int getTotalUsersCount() {
    return _demoUsers.length;
  }
}
