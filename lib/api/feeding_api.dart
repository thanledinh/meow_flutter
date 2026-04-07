import 'api_client.dart';
import 'endpoints.dart';

class FeedingApi {
  static final _client = ApiClient();

  // ─── Products (Kho thức ăn) ───────────────
  static Future<ApiResponse> addProduct(Map<String, dynamic> data) =>
      _client.post(Endpoints.feedingProducts, data);

  static Future<ApiResponse> quickAddProduct(Map<String, dynamic> data) =>
      _client.post(Endpoints.feedingProductQuickAdd, data);
  static Future<ApiResponse> getProducts() =>
      _client.get(Endpoints.feedingProducts);

  static Future<ApiResponse> deleteProduct(dynamic id) =>
      _client.delete(Endpoints.feedingProductDelete(id));

  static Future<ApiResponse> updateProduct(dynamic id, Map<String, dynamic> data) =>
      _client.put(Endpoints.feedingProductUpdate(id), data);

  static Future<ApiResponse> restockProduct(dynamic id, int addGrams, {bool force = false}) {
    final body = <String, dynamic>{'addGrams': addGrams};
    if (force) body['force'] = true;
    return _client.put(Endpoints.feedingProductRestock(id), body);
  }

  // ─── Plans (Khẩu phần) ────────────────────
  static Future<ApiResponse> generatePlans(Map<String, dynamic> data) =>
      _client.post(Endpoints.feedingPlansGenerate, data);

  static Future<ApiResponse> getPlans() =>
      _client.get(Endpoints.feedingPlans);

  static Future<ApiResponse> updatePlan(dynamic id, Map<String, dynamic> data) =>
      _client.put(Endpoints.feedingPlanUpdate(id), data);

  // ─── Today & Confirm ─────────────────────
  static Future<ApiResponse> getToday() =>
      _client.get(Endpoints.feedingToday);

  static Future<ApiResponse> confirmMeal(
    dynamic scheduleId, {
    String eatStatus = 'ate_all',
    String? note,
    int? portionAte,
  }) {
    final body = <String, dynamic>{'eatStatus': eatStatus};
    if (note != null) body['note'] = note;
    if (portionAte != null) body['portionAte'] = portionAte;
    return _client.post(Endpoints.feedingConfirm(scheduleId), body);
  }

  static Future<ApiResponse> getStreak() =>
      _client.get(Endpoints.feedingStreak);

  // ─── Transition (Chuyển đổi thức ăn) ─────
  static Future<ApiResponse> createTransition(Map<String, dynamic> data) =>
      _client.post(Endpoints.feedingTransition, data);

  // ─── Nutrition Stats ──────────────────────
  static Future<ApiResponse> getNutritionStats(dynamic petId) =>
      _client.get(Endpoints.nutritionStats(petId));

  // ─── Chat Sessions ────────────────────────
  static Future<ApiResponse> getChatSessions({dynamic petId}) {
    final url = petId != null
        ? '${Endpoints.aiChatSessions}?petId=$petId'
        : Endpoints.aiChatSessions;
    return _client.get(url);
  }

  // ─── Feeding History ────────────────────
  static Future<ApiResponse> getFeedingHistory({dynamic petId, int page = 1, int limit = 20}) {
    final params = <String>['page=$page', 'limit=$limit'];
    if (petId != null) params.add('petId=$petId');
    return _client.get('${Endpoints.feedingHistory}?${params.join('&')}');
  }
}
