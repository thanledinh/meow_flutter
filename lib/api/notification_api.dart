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
  static Future<ApiResponse> getHistory({int page = 1, int limit = 30, bool unreadOnly = false}) =>
      _client.get('${Endpoints.notifications}?page=$page&limit=$limit${unreadOnly ? '&unreadOnly=true' : ''}');

  /// Đánh dấu đã đọc 1 thông báo
  static Future<ApiResponse> markRead(dynamic id) =>
      _client.put(Endpoints.notificationRead(id), null);

  /// Đánh dấu đọc tất cả
  static Future<ApiResponse> readAll() =>
      _client.put(Endpoints.notificationsReadAll, null);

  /// Xóa token (tắt thông báo)
  static Future<ApiResponse> deleteToken(String token) =>
      _client.post(Endpoints.notificationsToken, {'token': token, 'action': 'delete'});
}
