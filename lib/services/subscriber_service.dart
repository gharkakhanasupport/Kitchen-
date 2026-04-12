import 'package:flutter/foundation.dart';
import '../models/subscriber.dart';
import '../utils/supabase_config.dart';
import 'sync_service.dart';

/// Service class for managing subscriber data.
/// All operations persisted to Supabase and synced to User DB.
class SubscriberService {
  final SyncService _sync = SyncService();
  static const String _table = 'subscribers';

  /// Get all subscribers for a cook
  Future<List<Subscriber>> getSubscribers(String cookId) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .order('created_at', ascending: false);

      return data.map((row) => Subscriber.fromMap(row)).toList();
    } catch (e) {
      debugPrint('SubscriberService.getSubscribers error: $e');
      return [];
    }
  }

  /// Get subscribers by status
  Future<List<Subscriber>> getSubscribersByStatus(
    String cookId,
    SubscriberStatus status,
  ) async {
    try {
      final statusStr = subscriberStatusToString(status);
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('cook_id', cookId)
          .eq('status', statusStr)
          .order('created_at', ascending: false);

      return data.map((row) => Subscriber.fromMap(row)).toList();
    } catch (e) {
      debugPrint('SubscriberService.getSubscribersByStatus error: $e');
      return [];
    }
  }

  /// Get active subscribers count
  Future<int> getActiveSubscribersCount(String cookId) async {
    final subs = await getSubscribersByStatus(cookId, SubscriberStatus.active);
    return subs.length;
  }

  /// Get subscriber by ID
  Future<Subscriber?> getSubscriberById(String subscriberId) async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .eq('id', subscriberId)
          .maybeSingle();

      return data != null ? Subscriber.fromMap(data) : null;
    } catch (e) {
      debugPrint('SubscriberService.getSubscriberById error: $e');
      return null;
    }
  }

  /// Add a new subscriber (synced to both DBs)
  Future<bool> addSubscriber(Subscriber subscriber) async {
    try {
      await _sync.dualInsert(_table, subscriber.toMap());
      return true;
    } catch (e) {
      debugPrint('SubscriberService.addSubscriber error: $e');
      return false;
    }
  }

  /// Update meal status (synced to both DBs)
  Future<bool> updateMealStatus(
    String subscriberId,
    MealStatus newStatus,
  ) async {
    try {
      await _sync.dualUpdate(
        _table,
        {'meal_status': newStatus.name},
        subscriberId,
      );
      return true;
    } catch (e) {
      debugPrint('SubscriberService.updateMealStatus error: $e');
      return false;
    }
  }

  /// Update subscriber status (synced to both DBs)
  Future<bool> updateSubscriberStatus(
    String subscriberId,
    SubscriberStatus newStatus,
  ) async {
    try {
      await _sync.dualUpdate(
        _table,
        {'status': subscriberStatusToString(newStatus)},
        subscriberId,
      );
      return true;
    } catch (e) {
      debugPrint('SubscriberService.updateSubscriberStatus error: $e');
      return false;
    }
  }

  /// Update today's meal for a subscriber (synced to both DBs)
  Future<bool> updateTodaysMeal(
    String subscriberId,
    String mealName,
  ) async {
    try {
      await _sync.dualUpdate(
        _table,
        {'todays_meal': mealName, 'meal_status': MealStatus.scheduled.name},
        subscriberId,
      );
      return true;
    } catch (e) {
      debugPrint('SubscriberService.updateTodaysMeal error: $e');
      return false;
    }
  }

  /// Delete a subscriber (synced to both DBs)
  Future<bool> deleteSubscriber(String subscriberId) async {
    try {
      await _sync.dualDelete(_table, subscriberId);
      return true;
    } catch (e) {
      debugPrint('SubscriberService.deleteSubscriber error: $e');
      return false;
    }
  }
}
