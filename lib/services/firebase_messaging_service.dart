import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/notification_api.dart';
import '../main.dart' show navigatorKey;

/// Background message handler — phải là top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('BG message: ${message.messageId}');
}

/// Firebase Messaging Service
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  static const _prefKey = 'notification_enabled';
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'moew_high', // id
    'Moew Thông báo', // name
    description: 'Thông báo từ ứng dụng Moew',
    importance: Importance.high,
    playSound: true,
  );

  /// Lấy token hiện tại (null nếu chưa init)
  String? get currentToken => _currentToken;

  /// Check trạng thái bật/tắt thông báo (local)
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  /// Khởi tạo: request permission, lấy token, lắng nghe
  Future<void> initialize() async {
    // ─── Setup local notifications ───
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(settings: const InitializationSettings(android: androidInit));

    // Create notification channel
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // ─── Request FCM permission ───
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied');
      return;
    }

    // ─── FCM Token ───
    _currentToken = await _messaging.getToken();
    if (_currentToken != null) {
      debugPrint('FCM Token: $_currentToken');
      final enabled = await isEnabled();
      if (enabled) {
        await _saveFcmToken(_currentToken!);
      }
    }

    // Lắng nghe token refresh
    _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      final enabled = await isEnabled();
      if (enabled) {
        await _saveFcmToken(token);
      }
    });

    // ─── Foreground messages → show local notification ───
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Khi user tap notification mở app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check nếu app mở từ notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Bật thông báo
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (_currentToken != null) {
      await _saveFcmToken(_currentToken!);
      debugPrint('Notifications ENABLED, token saved');
    }
  }

  /// Tắt thông báo
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
    if (_currentToken != null) {
      try {
        await NotificationApi.deleteToken(_currentToken!);
        debugPrint('Notifications DISABLED, token deleted');
      } catch (e) {
        debugPrint('Error deleting token: $e');
      }
    }
  }

  /// Gửi FCM token lên backend
  Future<void> _saveFcmToken(String token) async {
    try {
      await NotificationApi.saveToken(token, 'android');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Xử lý message khi app đang foreground → show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FG message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      id: notification.hashCode,
      title: notification.title ?? 'Moew',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Xử lý khi user tap notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Opened app from notification: ${message.data}');
    final screen = message.data['screen'];
    if (screen == 'HealthAlerts') {
      final petId = message.data['petId'];
      navigatorKey.currentState?.pushNamed(
        '/health-alerts',
        arguments: {'petId': petId},
      );
    }
  }
}
