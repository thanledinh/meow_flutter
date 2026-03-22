import 'api_client.dart';
import 'endpoints.dart';

class FeedApi {
  static final _client = ApiClient();

  /// Lấy danh sách bài viết
  static Future<ApiResponse> getAll({int page = 1, int limit = 20}) =>
      _client.get('${Endpoints.feed}?page=$page&limit=$limit');

  /// Tạo bài viết mới
  static Future<ApiResponse> create(Map<String, dynamic> data) =>
      _client.post(Endpoints.feed, data);

  /// Chi tiết bài viết
  static Future<ApiResponse> getById(dynamic postId) =>
      _client.get(Endpoints.feedDetail(postId));

  /// Thích bài viết
  static Future<ApiResponse> like(dynamic postId) =>
      _client.post(Endpoints.feedLike(postId), null);

  /// Lấy comments
  static Future<ApiResponse> getComments(dynamic postId) =>
      _client.get(Endpoints.feedComments(postId));

  /// Thêm comment
  static Future<ApiResponse> addComment(
          dynamic postId, Map<String, dynamic> data) =>
      _client.post(Endpoints.feedComments(postId), data);
}
