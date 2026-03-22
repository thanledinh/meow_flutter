import 'api_client.dart';
import 'endpoints.dart';

class NotificationApi {
  static final _client = ApiClient();

  /// Gửi notification cho 1 user
  static Future<ApiResponse> send(Map<String, dynamic> data) =>
      _client.post(Endpoints.notificationsSend, data);

  /// Gửi broadcast cho tất cả
  static Future<ApiResponse> sendAll(Map<String, dynamic> data) =>
      _client.post(Endpoints.notificationsSendAll, data);

  /// Lưu FCM/push token lên server
  static Future<ApiResponse> saveToken(String token, String platform) =>
      _client.post(
          Endpoints.notificationsToken, {'token': token, 'platform': platform});

  /// Lấy lịch sử thông báo
  static Future<ApiResponse> getHistory() =>
      _client.get(Endpoints.notifications);
}
