import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';

/// SyncService handles dual-writes to both Kitchen DB and User DB.
/// When Kitchen App writes data, it goes to both databases so the
/// User App can read it in real-time from its own DB.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SupabaseClient get _kitchenDb => SupabaseConfig.client;
  SupabaseClient get _userDb => SupabaseConfig.userDbClient;

  /// Insert a row into both Kitchen DB and User DB.
  /// Returns the inserted row from Kitchen DB.
  Future<Map<String, dynamic>> dualInsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    // Write to Kitchen DB (primary)
    final result =
        await _kitchenDb.from(table).insert(data).select().single();

    // Sync to User DB (use upsert for idempotency)
    try {
      await _userDb.from(table).upsert(result);
    } catch (e) {
      debugPrint('SyncService: User DB sync failed for $table insert: $e');
    }

    return result;
  }

  /// Upsert a row into both databases.
  /// Returns the upserted row from Kitchen DB.
  Future<Map<String, dynamic>> dualUpsert(
    String table,
    Map<String, dynamic> data, {
    String? onConflict,
  }) async {
    final result = await _kitchenDb
        .from(table)
        .upsert(data, onConflict: onConflict)
        .select()
        .single();

    try {
      await _userDb.from(table).upsert(result, onConflict: onConflict);
    } catch (e) {
      debugPrint('SyncService: User DB sync failed for $table upsert: $e');
    }

    return result;
  }

  /// Update a row in both databases by ID.
  Future<Map<String, dynamic>> dualUpdate(
    String table,
    Map<String, dynamic> data,
    String id,
  ) async {
    final result = await _kitchenDb
        .from(table)
        .update(data)
        .eq('id', id)
        .select()
        .single();

    try {
      await _userDb.from(table).update(data).eq('id', id);
    } catch (e) {
      debugPrint('SyncService: User DB sync failed for $table update: $e');
    }

    return result;
  }

  /// Update rows in both databases by a custom column filter.
  Future<void> dualUpdateWhere(
    String table,
    Map<String, dynamic> data, {
    required String column,
    required dynamic value,
  }) async {
    await _kitchenDb.from(table).update(data).eq(column, value);

    try {
      await _userDb.from(table).update(data).eq(column, value);
    } catch (e) {
      debugPrint('SyncService: User DB sync failed for $table updateWhere: $e');
    }
  }

  /// Delete a row from both databases by ID.
  Future<void> dualDelete(String table, String id) async {
    await _kitchenDb.from(table).delete().eq('id', id);

    try {
      await _userDb.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('SyncService: User DB sync failed for $table delete: $e');
    }
  }

  /// Read from Kitchen DB only (no sync needed for reads).
  Future<List<Map<String, dynamic>>> read(
    String table, {
    String? column,
    dynamic value,
  }) async {
    var query = _kitchenDb.from(table).select();
    if (column != null && value != null) {
      return await query.eq(column, value);
    }
    return await query;
  }

  /// Read a single row from Kitchen DB.
  Future<Map<String, dynamic>?> readSingle(
    String table, {
    required String column,
    required dynamic value,
  }) async {
    return await _kitchenDb
        .from(table)
        .select()
        .eq(column, value)
        .maybeSingle();
  }
}
