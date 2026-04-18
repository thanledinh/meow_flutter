import 'api_client.dart';
import 'endpoints.dart';

class PetApi {
  static final _client = ApiClient();

  /// Danh sách pet của user
  static Future<ApiResponse> getAll() => _client.get(Endpoints.pets);

  /// Chi tiết 1 pet
  static Future<ApiResponse> getById(dynamic petId) =>
      _client.get(Endpoints.petDetail(petId));

  /// Thêm pet mới
  static Future<ApiResponse> create(Map<String, dynamic> data) =>
      _client.post(Endpoints.pets, data);

  /// Cập nhật thông tin pet
  static Future<ApiResponse> update(
          dynamic petId, Map<String, dynamic> data) =>
      _client.put(Endpoints.petUpdate(petId), data);

  /// Xóa pet
  static Future<ApiResponse> delete(dynamic petId) =>
      _client.delete(Endpoints.petDelete(petId));

  /// Upload avatar cho pet (base64)
  static Future<ApiResponse> uploadAvatar(dynamic petId, String base64) =>
      _client.post(Endpoints.petAvatarB64(petId), {'image': base64});

  // ─── Weight Tracking ──────────────────
  static Future<ApiResponse> addWeight(dynamic petId, Map<String, dynamic> data) =>
      _client.post(Endpoints.petWeight(petId), data);

  static Future<ApiResponse> getWeightHistory(dynamic petId, {int months = 3}) =>
      _client.get('${Endpoints.petWeight(petId)}?months=$months');

  static Future<ApiResponse> deleteWeightLog(dynamic petId, dynamic logId) =>
      _client.delete(Endpoints.petWeightDelete(petId, logId));

  static Future<ApiResponse> getWeightReminder() =>
      _client.get(Endpoints.petWeightReminder);

  // ─── Vaccine Schedule ─────────────────
  static Future<ApiResponse> addVaccine(dynamic petId, Map<String, dynamic> data) =>
      _client.post(Endpoints.petVaccines(petId), data);

  static Future<ApiResponse> getVaccines(dynamic petId) =>
      _client.get(Endpoints.petVaccines(petId));

  static Future<ApiResponse> updateVaccine(dynamic petId, dynamic vaccineId, Map<String, dynamic> data) =>
      _client.put(Endpoints.petVaccineDetail(petId, vaccineId), data);

  static Future<ApiResponse> deleteVaccine(dynamic petId, dynamic vaccineId) =>
      _client.delete(Endpoints.petVaccineDetail(petId, vaccineId));

  static Future<ApiResponse> getUpcomingVaccines({int days = 30}) =>
      _client.get('${Endpoints.petVaccinesUpcoming}?days=$days');

  /// Aggregated schedule — gộp feeding/vaccine/booking/weigh_in vào 1 call duy nhất
  static Future<ApiResponse> getSchedule(dynamic petId) =>
      _client.get(Endpoints.petSchedule(petId));
}
