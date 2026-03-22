import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../api/notification_api.dart';

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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Khởi tạo: request permission, lấy token, lắng nghe
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        'FCM permission: ${settings.authorizationStatus}');

    // Lấy FCM token → gửi lên server
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _saveFcmToken(token);
    }

    // Lắng nghe token refresh
    _messaging.onTokenRefresh.listen(_saveFcmToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Khi user tap notification mở app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check nếu app mở từ notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
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

  /// Xử lý message khi app đang foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FG message: ${message.notification?.title}');
    // Có thể show local notification hoặc toast ở đây
  }

  /// Xử lý khi user tap notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Opened app from notification: ${message.data}');
    // Có thể navigate đến screen tương ứng dựa trên message.data
  }
}
