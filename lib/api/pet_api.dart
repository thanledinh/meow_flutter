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
}
