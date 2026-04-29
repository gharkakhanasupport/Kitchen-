import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background notification plugin (top-level for isolate handler)
final FlutterLocalNotificationsPlugin _bgLocalNotifications =
    FlutterLocalNotificationsPlugin();

/// Top-level background message handler.
/// Must be top-level function (not class method) for Flutter's background isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('🔔 Kitchen BG message received');
  debugPrint('📦 Data payload: ${message.data}');

  final data = message.data;
  if (data.isEmpty || data['title'] == null) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _bgLocalNotifications.initialize(initSettings);

  const androidChannel = AndroidNotificationChannel(
    'gkk_kitchen_orders',
    'Kitchen Order Alerts',
    description: 'New order & order status notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await _bgLocalNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(androidChannel);

  const androidDetails = AndroidNotificationDetails(
    'gkk_kitchen_orders',
    'Kitchen Order Alerts',
    channelDescription: 'New order & order status notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF16A34A),
    enableVibration: true,
    playSound: true,
  );

  final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await _bgLocalNotifications.show(
    notificationId,
    data['title']?.toString() ?? 'Kitchen',
    data['body']?.toString() ?? '',
    const NotificationDetails(android: androidDetails),
  );

  debugPrint('✅ Kitchen BG notification shown');
}

/// FCM push notification service for Kitchen App.
///
/// Handles:
/// - new order alerts (from User App via Edge Function)
/// - status updates from Delivery App (pickup confirmation etc.)
///
/// Call [initialize] once in main.dart, then [registerTokenWithSupabase]
/// after kitchen owner logs in.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await _requestPermissions();
      await _initializeLocalNotifications();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      final token = await _messaging.getToken();
      debugPrint('📱 Kitchen FCM Token: $token');

      _isInitialized = true;
      debugPrint('✅ Kitchen FCM Service initialized');
    } catch (e) {
      debugPrint('❌ Kitchen FCM init error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔐 Kitchen notif permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('📲 Kitchen notif tap: ${response.payload}');
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'gkk_kitchen_orders',
      'Kitchen Order Alerts',
      description: 'New order & order status notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Kitchen FG message: ${message.data}');

    final data = message.data;
    if (data.isEmpty || data['title'] == null) return;

    final title = data['title']?.toString() ?? 'Kitchen';
    final body = data['body']?.toString() ?? '';
    _showLocalNotification(title: title, body: body, payload: data.toString());
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gkk_kitchen_orders',
      'Kitchen Order Alerts',
      channelDescription: 'New order & order status notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF16A34A),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📲 Kitchen notif tapped: ${message.data}');
    // Navigate to orders screen based on data['order_id']
  }

  /// Returns current FCM device token.
  Future<String?> getToken() => _messaging.getToken();

  /// Register this device's FCM token in Supabase `fcm_tokens` table.
  /// Kitchen uses phone-auth mock (no Supabase auth), so pass [cookId] explicitly.
  /// Call after profile loads. Also wires token refresh listener.
  Future<void> registerTokenWithSupabase(String cookId) async {
    if (cookId.isEmpty) {
      debugPrint('⚠️ Kitchen FCM: cookId empty');
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Kitchen FCM: no device token');
        return;
      }

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'web';

      await Supabase.instance.client.rpc(
        'register_fcm_token_for_user',
        params: {
          'p_user_id': cookId,
          'p_device_token': token,
          'p_user_type': 'kitchen',
          'p_platform': platform,
        },
      );
      debugPrint('✅ Kitchen FCM token registered for $cookId');

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await Supabase.instance.client.rpc(
            'register_fcm_token_for_user',
            params: {
              'p_user_id': cookId,
              'p_device_token': newToken,
              'p_user_type': 'kitchen',
              'p_platform': platform,
            },
          );
          debugPrint('✅ Kitchen FCM token refreshed');
        } catch (e) {
          debugPrint('⚠️ Kitchen FCM refresh failed: $e');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Kitchen FCM register failed: $e');
    }
  }
}
