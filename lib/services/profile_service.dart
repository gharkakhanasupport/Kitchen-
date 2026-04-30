import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cook.dart';
import '../utils/supabase_config.dart';
import 'sync_service.dart';

/// Profile Service
/// Manages cook profile data and syncs to kitchens table in both DBs.
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SyncService _sync = SyncService();

  // Cache for current cook profile
  Cook? _currentCook;

  // Single cache key for consistency
  static const String _cacheKey = 'cook_profile';

  /// Get current cook profile from memory or local storage.
  Future<Cook?> getCurrentProfile() async {
    if (_currentCook != null) return _currentCook;

    final prefs = await SharedPreferences.getInstance();
    // Check both legacy keys for backwards compatibility
    String? cookJson = prefs.getString(_cacheKey);
    cookJson ??= prefs.getString('cook_data');

    if (cookJson != null) {
      try {
        final cookMap = jsonDecode(cookJson) as Map<String, dynamic>;
        _currentCook = Cook.fromMap(cookMap);
        return _currentCook;
      } catch (e) {
        debugPrint('Error parsing cook profile: $e');
      }
    }
    return null;
  }

  /// Save cook to local storage and memory cache.
  Future<void> _saveToCache(Cook cook) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(cook.toMap());
    await prefs.setString(_cacheKey, json);
    // Also update legacy key so both are in sync
    await prefs.setString('cook_data', json);
    _currentCook = cook;
  }

  /// Refresh profile from Supabase.
  /// Does NOT re-sync to kitchens table (avoids overwriting recent updates).
  Future<Cook?> refreshProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('cook_email');
      final phone = prefs.getString('phone_number');

      if (email == null && phone == null) return getCurrentProfile();

      // Clear in-memory cache so we fetch fresh data
      _currentCook = null;

      var query = SupabaseConfig.client.from('cooks').select();
      
      if (email != null && email.isNotEmpty) {
        query = query.eq('email', email);
      } else {
        query = query.eq('phone', phone!);
      }

      final result = await query.maybeSingle();

      if (result != null) {
        final cook = Cook.fromMap(result);
        await _saveToCache(cook);
        debugPrint('ProfileService: Refreshed profile. profileImageUrl=${cook.profileImageUrl}');
        
        // IMPORTANT: Also update _currentCook manually to be sure
        _currentCook = cook;
        
        return cook;
      }
    } catch (e) {
      debugPrint('Error refreshing profile from Supabase: $e');
    }
    return getCurrentProfile();
  }

  /// Sync cook data to the kitchens table (both Kitchen DB and User DB).
  /// This is what the User app reads.
  Future<void> _syncToKitchensTable(Cook cook) async {
    try {
      final kitchenData = _cookToKitchenMap(cook);
      debugPrint('ProfileService: syncing to kitchens table. profile_image_url=${kitchenData['profile_image_url']}');
      await _sync.dualUpsert('kitchens', kitchenData, onConflict: 'cook_id');
      debugPrint('ProfileService: kitchens table sync SUCCESS');
    } catch (e) {
      debugPrint('ProfileService: kitchens table sync failed: $e');
    }
  }

  /// Convert Cook object to kitchens table row format
  Map<String, dynamic> _cookToKitchenMap(Cook cook) {
    return {
      'cook_id': cook.id,
      'kitchen_name': cook.kitchenName,
      'description': cook.specialty,
      'owner_name': cook.ownerName,
      'phone': cook.phoneNumber,
      'email': cook.email,
      'location': cook.address,
      'is_available': cook.isAvailable,
      'is_vegetarian': cook.isVegetarian,
      'kitchen_photos': cook.kitchenPhotos,
      'rating': cook.rating,
      'total_orders': cook.totalOrders,
      'profile_image_url': cook.profileImageUrl,
    };
  }

  /// Create a new cook profile
  Future<bool> createProfile({
    required String phoneNumber,
    required String kitchenName,
    required String ownerName,
    required String address,
    required String specialty,
    bool isVegetarian = false,
  }) async {
    try {
      final newCook = Cook(
        id: phoneNumber, // Use phone as ID for now
        phoneNumber: phoneNumber,
        email: '', // Will be updated later
        kitchenName: kitchenName,
        ownerName: ownerName,
        address: address,
        specialty: specialty,
        isVegetarian: isVegetarian,
        createdAt: DateTime.now(),
      );

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cook_email', '');
      await _saveToCache(newCook);

      // Sync to kitchens table in both DBs
      await _syncToKitchensTable(newCook);

      return true;
    } catch (e) {
      debugPrint('Error creating profile: $e');
      return false;
    }
  }

  /// Update existing cook profile and sync to both databases.
  /// This is the core method — it updates cooks table, syncs to kitchens
  /// table in both DBs, and saves to local cache.
  Future<bool> updateProfile({
    String? email,
    String? kitchenName,
    String? ownerName,
    String? address,
    String? specialty,
    String? profileImageUrl,
    bool? isAvailable,
    bool? isVegetarian,
  }) async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile == null) {
        throw Exception('No profile found to update');
      }

      final updatedCook = currentProfile.copyWith(
        email: email,
        kitchenName: kitchenName,
        ownerName: ownerName,
        address: address,
        specialty: specialty,
        profileImageUrl: profileImageUrl,
        isAvailable: isAvailable,
        isVegetarian: isVegetarian,
      );

      debugPrint('ProfileService.updateProfile: profileImageUrl=$profileImageUrl');
      debugPrint('ProfileService.updateProfile: updatedCook.profileImageUrl=${updatedCook.profileImageUrl}');

      // Build the update map for cooks table
      final cooksUpdate = <String, dynamic>{};
      if (kitchenName != null) cooksUpdate['kitchen_name'] = kitchenName;
      if (specialty != null) cooksUpdate['kitchen_description'] = specialty;
      if (isAvailable != null) cooksUpdate['is_available'] = isAvailable;
      if (profileImageUrl != null) cooksUpdate['profile_image_url'] = profileImageUrl;
      if (isVegetarian != null) cooksUpdate['is_vegetarian'] = isVegetarian;

      // 1. Update cooks table in Kitchen DB (try by id first, fallback to phone)
      if (cooksUpdate.isNotEmpty) {
        try {
          if (updatedCook.id.isNotEmpty) {
            await SupabaseConfig.client
                .from('cooks')
                .update(cooksUpdate)
                .eq('id', updatedCook.id);
          } else {
            await SupabaseConfig.client
                .from('cooks')
                .update(cooksUpdate)
                .eq('phone', updatedCook.phoneNumber);
          }
          debugPrint('ProfileService: cooks table updated OK');
        } catch (e) {
          debugPrint('ProfileService: cooks table update failed: $e');
        }
      }

      // 2. Sync to kitchens table in BOTH DBs (this is what the User app sees)
      await _syncToKitchensTable(updatedCook);

      // 3. Save to local cache AFTER successful DB writes
      await _saveToCache(updatedCook);

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Toggle availability status (synced to both DBs)
  Future<bool> toggleAvailability() async {
    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile == null) {
        throw Exception('No profile found');
      }

      return await updateProfile(isAvailable: !currentProfile.isAvailable);
    } catch (e) {
      debugPrint('Error toggling availability: $e');
      return false;
    }
  }

  /// Get availability status
  Future<bool> getAvailabilityStatus() async {
    final profile = await getCurrentProfile();
    return profile?.isAvailable ?? false;
  }

  /// Create initial kitchens entry when cook is approved.
  /// Call this after admin approves a kitchen application.
  Future<void> createKitchenEntry(Cook cook) async {
    await _syncToKitchensTable(cook);
  }

  /// Clear in-memory cache so next read picks up fresh data
  void clearCache() {
    _currentCook = null;
  }

  /// Clear profile data
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove('cook_data');
    _currentCook = null;
  }
}
