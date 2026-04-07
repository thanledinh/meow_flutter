import '../api/api_client.dart';
import '../api/endpoints.dart';

class PostApi {
  /// Đăng bài mới
  static Future<ApiResponse> createPost({
    required String caption,
    required List<String> images,
    required List<int> petIds,
    String visibility = 'public',
  }) async {
    return ApiClient().request(
      Endpoints.posts,
      method: 'POST',
      body: {
        'caption': caption,
        'images': images,
        'petIds': petIds,
        'visibility': visibility,
      },
    );
  }

  /// Cập nhật bài (theo Social v2 - caption và visibility)
  static Future<ApiResponse> updatePost(dynamic id, {
    String? caption,
    String? visibility,
  }) async {
    final Map<String, dynamic> body = {};
    if (caption != null) body['caption'] = caption;
    if (visibility != null) body['visibility'] = visibility;
    
    return ApiClient().request(
      Endpoints.postUpdate(id),
      method: 'PUT',
      body: body,
    );
  }

  /// Lấy Feed
  static Future<ApiResponse> getFeed({dynamic cursor, int limit = 20}) async {
    final String query = (cursor != null) ? '?limit=$limit&cursor=$cursor' : '?limit=$limit';
    return ApiClient().request('${Endpoints.posts}$query');
  }

  /// Bài đăng của tôi
  static Future<ApiResponse> getMyPosts({int page = 1, int limit = 20}) async {
    return ApiClient().request('${Endpoints.postsMe}?page=$page&limit=$limit');
  }

  /// Bài đăng theo tag pet
  static Future<ApiResponse> getPetPosts(int petId, {int page = 1, int limit = 20}) async {
    return ApiClient().request('${Endpoints.postsPet(petId)}?page=$page&limit=$limit');
  }

  /// Chi tiết bài
  static Future<ApiResponse> getPostDetail(int id) async {
    return ApiClient().request(Endpoints.postDetail(id));
  }

  /// Xóa bài
  static Future<ApiResponse> deletePost(int id) async {
    return ApiClient().request(Endpoints.postDetail(id), method: 'DELETE');
  }
}
