import 'api_client.dart';
import 'endpoints.dart';

class UploadApi {
  static final _client = ApiClient();

  /// Upload ảnh
  static Future<ApiResponse> image(String filePath) =>
      _client.upload(Endpoints.uploadImage, filePath, fieldName: 'image');

  /// Upload avatar
  static Future<ApiResponse> avatar(String filePath) =>
      _client.upload(Endpoints.uploadAvatar, filePath, fieldName: 'avatar');
}
