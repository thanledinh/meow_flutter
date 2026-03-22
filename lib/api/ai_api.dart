import 'api_client.dart';
import 'endpoints.dart';

class AiApi {
  static final _client = ApiClient();

  /// Phân tích ảnh thức ăn bằng AI Vision
  static Future<ApiResponse> analyzeFood(Map<String, dynamic> data) =>
      _client.post(Endpoints.aiAnalyzeFood, data);

  /// Bắt đầu phiên chat AI mới
  static Future<ApiResponse> chatStart(Map<String, dynamic> data) =>
      _client.post(Endpoints.aiChatStart, data);

  /// Gửi tin nhắn trong phiên chat
  static Future<ApiResponse> chatSend(dynamic sessionId, String message) =>
      _client.post(Endpoints.aiChatSend(sessionId), {'message': message});

  /// Lấy lịch sử chat
  static Future<ApiResponse> chatHistory(dynamic sessionId) =>
      _client.get(Endpoints.aiChatHistory(sessionId));

  /// Lịch sử ăn uống của pet
  static Future<ApiResponse> foodHistory(dynamic petId,
      {String? date, String? from, String? to}) {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final qs = params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    return _client.get('${Endpoints.foodHistory(petId)}$qs');
  }

  /// Nhập thủ công bản ghi ăn
  static Future<ApiResponse> addFoodLog(
          dynamic petId, Map<String, dynamic> data) =>
      _client.post(Endpoints.foodLogCreate(petId), data);

  /// Xóa bản ghi ăn
  static Future<ApiResponse> deleteFoodLog(dynamic petId, dynamic id) =>
      _client.delete(Endpoints.foodLogDelete(petId, id));
}
