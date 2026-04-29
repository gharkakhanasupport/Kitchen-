import 'package:flutter/foundation.dart';
import '../utils/supabase_config.dart';

/// Kitchen Wallet Service
/// Tracks earnings from completed orders.
/// Writes to Kitchen DB's kitchen_wallets and kitchen_wallet_transactions tables.
class KitchenWalletService {
  static final KitchenWalletService _instance = KitchenWalletService._internal();
  factory KitchenWalletService() => _instance;
  KitchenWalletService._internal();

  /// Get current wallet balance for a cook
  Future<double> getBalance(String cookId) async {
    try {
      final data = await SupabaseConfig.client
          .from('kitchen_wallets')
          .select('balance')
          .eq('cook_id', cookId)
          .maybeSingle();
      if (data == null) return 0.0;
      return (data['balance'] ?? 0).toDouble();
    } catch (e) {
      debugPrint('KitchenWalletService.getBalance error: $e');
      return 0.0;
    }
  }

  /// Get total lifetime earnings
  Future<double> getTotalEarnings(String cookId) async {
    try {
      final data = await SupabaseConfig.client
          .from('kitchen_wallets')
          .select('total_earnings')
          .eq('cook_id', cookId)
          .maybeSingle();
      if (data == null) return 0.0;
      return (data['total_earnings'] ?? 0).toDouble();
    } catch (e) {
      debugPrint('KitchenWalletService.getTotalEarnings error: $e');
      return 0.0;
    }
  }

  /// Credit earnings when an order is completed
  Future<bool> creditEarning(String cookId, double amount, String orderId) async {
    try {
      // Get current balance
      final currentData = await SupabaseConfig.client
          .from('kitchen_wallets')
          .select()
          .eq('cook_id', cookId)
          .maybeSingle();

      final currentBalance = currentData != null ? (currentData['balance'] ?? 0).toDouble() : 0.0;
      final currentTotalEarnings = currentData != null ? (currentData['total_earnings'] ?? 0).toDouble() : 0.0;

      // Upsert wallet balance
      await SupabaseConfig.client.from('kitchen_wallets').upsert({
        'cook_id': cookId,
        'balance': currentBalance + amount,
        'total_earnings': currentTotalEarnings + amount,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'cook_id');

      // Record transaction
      await SupabaseConfig.client.from('kitchen_wallet_transactions').insert({
        'cook_id': cookId,
        'amount': amount,
        'transaction_type': 'order_earning',
        'status': 'completed',
        'order_id': orderId,
        'description': 'Earning from order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
      });

      debugPrint('KitchenWalletService: Credited \u20B9$amount to $cookId for order $orderId');
      return true;
    } catch (e) {
      debugPrint('KitchenWalletService.creditEarning error: $e');
      return false;
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactions(String cookId) async {
    try {
      return await SupabaseConfig.client
          .from('kitchen_wallet_transactions')
          .select()
          .eq('cook_id', cookId)
          .order('created_at', ascending: false)
          .limit(50);
    } catch (e) {
      debugPrint('KitchenWalletService.getTransactions error: $e');
      return [];
    }
  }

  /// Real-time stream of wallet balance
  Stream<double> getBalanceStream(String cookId) {
    return SupabaseConfig.client
        .from('kitchen_wallets')
        .stream(primaryKey: ['cook_id'])
        .eq('cook_id', cookId)
        .map((rows) {
          if (rows.isEmpty) return 0.0;
          return (rows.first['balance'] ?? 0).toDouble();
        });
  }

  /// Ensure wallet row exists for a cook
  Future<void> ensureWalletExists(String cookId) async {
    try {
      final data = await SupabaseConfig.client
          .from('kitchen_wallets')
          .select('cook_id')
          .eq('cook_id', cookId)
          .maybeSingle();
      if (data == null) {
        await SupabaseConfig.client.from('kitchen_wallets').insert({
          'cook_id': cookId,
          'balance': 0.0,
          'total_earnings': 0.0,
        });
      }
    } catch (e) {
      debugPrint('KitchenWalletService.ensureWalletExists error: $e');
    }
  }
}
