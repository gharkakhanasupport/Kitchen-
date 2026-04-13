import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../utils/supabase_config.dart';
import 'sync_service.dart';
import 'daily_menu_service.dart';

/// Service class for managing menu items.
/// All operations are persisted to Supabase and synced to User DB.
class MenuService {
  final SyncService _sync = SyncService();
  static const String _table = 'menu_items';

  /// Get all menu items for a specific cook
  Future<List<MenuItem>> getMenuItems(String cookId) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .order('created_at', ascending: false);

      return data.map((row) => MenuItem.fromMap(row)).toList();
    } catch (e) {
      debugPrint('MenuService.getMenuItems error: $e');
      return [];
    }
  }

  /// Get a single menu item by ID
  Future<MenuItem?> getMenuItemById(String itemId) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('id', itemId)
          .maybeSingle();

      return data != null ? MenuItem.fromMap(data) : null;
    } catch (e) {
      debugPrint('MenuService.getMenuItemById error: $e');
      return null;
    }
  }

  /// Add a new menu item (synced to both DBs)
  Future<bool> addMenuItem(MenuItem item) async {
    try {
      await _sync.dualInsert(_table, item.toInsertMap());
      return true;
    } catch (e) {
      debugPrint('MenuService.addMenuItem error: $e');
      return false;
    }
  }

  /// Update an existing menu item (synced to both DBs)
  Future<bool> updateMenuItem(MenuItem item) async {
    try {
      await _sync.dualUpdate(_table, item.toMap(), item.id);
      return true;
    } catch (e) {
      debugPrint('MenuService.updateMenuItem error: $e');
      return false;
    }
  }

  /// Delete a menu item (synced to both DBs)
  Future<bool> deleteMenuItem(String itemId) async {
    try {
      await _sync.dualDelete(_table, itemId);
      return true;
    } catch (e) {
      debugPrint('MenuService.deleteMenuItem error: $e');
      return false;
    }
  }

  /// Emergency method to remove the stuck Chicken dish
  Future<void> removeStuckChicken() async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select('id')
          .eq('name', 'Chicken')
          .eq('price', 50)
          .maybeSingle();

      if (data != null) {
        await deleteMenuItem(data['id']);
      }
    } catch (e) {
      debugPrint('Error removing stuck chicken: $e');
    }
  }

  /// Toggle item availability (synced to both DBs)
  Future<bool> toggleItemAvailability(String itemId) async {
    try {
      // Get current state
      final item = await getMenuItemById(itemId);
      if (item == null) return false;

      await _sync.dualUpdate(
        _table,
        {'is_available': !item.isAvailable},
        itemId,
      );
      return true;
    } catch (e) {
      debugPrint('MenuService.toggleItemAvailability error: $e');
      return false;
    }
  }

  /// Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(
    String cookId,
    String category,
  ) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .eq('category', category)
          .order('created_at', ascending: false);

      return data.map((row) => MenuItem.fromMap(row)).toList();
    } catch (e) {
      debugPrint('MenuService.getMenuItemsByCategory error: $e');
      return [];
    }
  }

  /// Get only available menu items for a cook
  Future<List<MenuItem>> getAvailableMenuItems(String cookId) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .eq('is_available', true)
          .order('category');

      return data.map((row) => MenuItem.fromMap(row)).toList();
    } catch (e) {
      debugPrint('MenuService.getAvailableMenuItems error: $e');
      return [];
    }
  }

  /// Auto-cleanup old daily menus (older than 3 days) from both DBs.
  Future<void> cleanupOldDailyMenus() async {
    await DailyMenuService().cleanupOldMenus();
  }
}
