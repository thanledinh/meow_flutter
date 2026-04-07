import 'api_client.dart';
import 'endpoints.dart';

class FeedApi {
  static final _client = ApiClient();

  /// Lấy danh sách bài viết (feed)
  static Future<ApiResponse> getAll({dynamic cursor, int limit = 20}) {
    final String query = (cursor != null) ? '?limit=$limit&cursor=$cursor' : '?limit=$limit';
    return _client.get('${Endpoints.posts}$query');
  }

  /// Tạo bài viết mới
  static Future<ApiResponse> create(Map<String, dynamic> data) =>
      _client.post(Endpoints.posts, data);

  /// Chi tiết bài viết (kèm comments)
  static Future<ApiResponse> getById(dynamic postId) =>
      _client.get(Endpoints.postDetail(postId));

  /// Toggle like / unlike
  static Future<ApiResponse> like(dynamic postId) =>
      _client.post(Endpoints.postLike(postId), null);

  /// Lấy comments (có phân trang)
  static Future<ApiResponse> getComments(dynamic postId,
          {int page = 1, int limit = 20}) =>
      _client.get('${Endpoints.postComments(postId)}?page=$page&limit=$limit');

  /// Thêm comment
  static Future<ApiResponse> addComment(
          dynamic postId, Map<String, dynamic> data) =>
      _client.post(Endpoints.postComments(postId), data);

  /// Xóa comment
  static Future<ApiResponse> deleteComment(
          dynamic postId, dynamic commentId) =>
      _client.delete(Endpoints.postCommentDelete(postId, commentId));
}
