import 'api_client.dart';
import 'endpoints.dart';

class SosApi {
  static final _client = ApiClient();

  /// Bấm SOS — gửi cảnh báo cấp cứu
  static Future<ApiResponse> trigger(Map<String, dynamic> data) =>
      _client.post(Endpoints.sosTrigger, data);

  /// Clinic nhận ca
  static Future<ApiResponse> accept(dynamic sosId, dynamic clinicId) =>
      _client.post(Endpoints.sosAccept(sosId), {'clinicId': clinicId});

  /// Hoàn thành + thanh toán
  static Future<ApiResponse> complete(dynamic sosId,
          {double? totalCost, bool? payByWallet}) =>
      _client.post(Endpoints.sosComplete(sosId), {
        'totalCost': ?totalCost,
        'payByWallet': ?payByWallet,
      });

  /// Hủy SOS
  static Future<ApiResponse> cancel(dynamic sosId) =>
      _client.post(Endpoints.sosCancel(sosId), null);

  /// Lịch sử SOS
  static Future<ApiResponse> getHistory() =>
      _client.get(Endpoints.sosHistory);
}
