import 'api_client.dart';

class EkycApi {
  static final _client = ApiClient();

  /// Submit xác minh CCCD
  static Future<ApiResponse> submit(Map<String, dynamic> data) =>
      _client.post('/auth/ekyc', data);

  /// Check trạng thái eKYC
  static Future<ApiResponse> getStatus() => _client.get('/auth/ekyc/status');
}
