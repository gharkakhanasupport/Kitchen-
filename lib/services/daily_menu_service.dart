import 'package:flutter/foundation.dart';
import '../models/daily_menu.dart';
import '../models/daily_menu_item.dart';
import '../utils/supabase_config.dart';
import 'sync_service.dart';

/// Daily Menu Service
/// Manages daily menu data with Supabase persistence and dual-write sync.
class DailyMenuService {
  final SyncService _sync = SyncService();
  static const String _table = 'daily_menus';

  /// Get menu for a specific date and cook
  Future<DailyMenu> getDailyMenu(DateTime date, String cookId) async {
    try {
      final dateStr = _getDateKey(date);
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .eq('date', dateStr)
          .order('category');

      if (data.isEmpty) {
        return DailyMenu(date: date, items: []);
      }

      final items = data.map((row) => DailyMenuItem.fromMap(row)).toList();
      return DailyMenu(date: date, items: items);
    } catch (e) {
      debugPrint('DailyMenuService.getDailyMenu error: $e');
      return DailyMenu(date: date, items: []);
    }
  }

  /// Add a daily menu item (synced to both DBs)
  Future<bool> addDailyMenuItem(
    DateTime date,
    String cookId,
    DailyMenuItem item,
  ) async {
    try {
      final data = {
        'cook_id': cookId,
        'date': _getDateKey(date),
        ...item.toMap(),
      };
      await _sync.dualInsert(_table, data);
      return true;
    } catch (e) {
      debugPrint('DailyMenuService.addDailyMenuItem error: $e');
      return false;
    }
  }

  /// Update a daily menu item (synced to both DBs)
  Future<bool> updateMenuItem(DateTime date, DailyMenuItem updatedItem) async {
    try {
      await _sync.dualUpdate(_table, updatedItem.toMap(), updatedItem.id);
      return true;
    } catch (e) {
      debugPrint('DailyMenuService.updateMenuItem error: $e');
      return false;
    }
  }

  /// Publish/save entire menu for a date (synced to both DBs)
  Future<bool> publishMenu(
    DateTime date,
    String cookId,
    List<DailyMenuItem> items,
  ) async {
    try {
      final dateStr = _getDateKey(date);

      for (final item in items) {
        final data = {
          'cook_id': cookId,
          'date': dateStr,
          ...item.toMap(),
        };
        // Upsert so publishing is idempotent
        await _sync.dualUpsert(_table, data, onConflict: 'cook_id,date,name');
      }
      return true;
    } catch (e) {
      debugPrint('DailyMenuService.publishMenu error: $e');
      return false;
    }
  }

  /// Delete a daily menu item (synced to both DBs)
  Future<bool> deleteDailyMenuItem(String itemId) async {
    try {
      await _sync.dualDelete(_table, itemId);
      return true;
    } catch (e) {
      debugPrint('DailyMenuService.deleteDailyMenuItem error: $e');
      return false;
    }
  }

  /// Clear all menu items for a date (synced to both DBs)
  Future<bool> clearDailyMenu(DateTime date, String cookId) async {
    try {
      final dateStr = _getDateKey(date);

      await SupabaseConfig.client
          .from(_table)
          .delete()
          .eq('cook_id', cookId)
          .eq('date', dateStr);

      try {
        await SupabaseConfig.userDbClient
            .from(_table)
            .delete()
            .eq('cook_id', cookId)
            .eq('date', dateStr);
      } catch (e) {
        debugPrint('DailyMenuService: User DB clear failed: $e');
      }

      return true;
    } catch (e) {
      debugPrint('DailyMenuService.clearDailyMenu error: $e');
      return false;
    }
  }

  /// Get date key in YYYY-MM-DD format
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
