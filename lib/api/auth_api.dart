import 'api_client.dart';
import 'endpoints.dart';

class AuthApi {
  static final _client = ApiClient();

  /// Đăng ký tài khoản mới
  static Future<ApiResponse> register(Map<String, dynamic> data) async {
    final result =
        await _client.post(Endpoints.authRegister, data, auth: false);
    final payload =
        (result.data as Map<String, dynamic>?)?['data'] ?? result.data;
    if (result.success && payload is Map && payload['token'] != null) {
      await TokenManager.save(
        payload['token'] as String,
        payload['user'] as Map<String, dynamic>?,
        refreshToken: payload['refreshToken'] as String?,
      );
    }
    return result;
  }

  /// Đăng nhập Social
  static Future<ApiResponse> socialLogin(String idToken) async {
    final result = await _client.post(Endpoints.authSocialLogin, {'token': idToken}, auth: false);
    final payload = (result.data as Map<String, dynamic>?)?['data'] ?? result.data;
    if (result.success && payload is Map && payload['token'] != null) {
      await TokenManager.save(
        payload['token'] as String,
        payload['user'] as Map<String, dynamic>?,
        refreshToken: payload['refreshToken'] as String?,
      );
    }
    return result;
  }

  /// Đăng nhập
  static Future<ApiResponse> login(Map<String, dynamic> data) async {
    final result = await _client.post(Endpoints.authLogin, data, auth: false);
    final payload =
        (result.data as Map<String, dynamic>?)?['data'] ?? result.data;
    if (result.success && payload is Map && payload['token'] != null) {
      await TokenManager.save(
        payload['token'] as String,
        payload['user'] as Map<String, dynamic>?,
        refreshToken: payload['refreshToken'] as String?,
      );
    }
    return result;
  }

  /// Đăng xuất
  static Future<void> logout() async {
    await TokenManager.clear();
  }

  /// Quên mật khẩu
  static Future<ApiResponse> forgotPassword(String email) =>
      _client.post(Endpoints.authForgotPassword, {'email': email}, auth: false);

  /// Lấy profile
  static Future<ApiResponse> getProfile() =>
      _client.get(Endpoints.authProfile);

  /// Cập nhật profile
  static Future<ApiResponse> updateProfile(Map<String, dynamic> data) =>
      _client.put(Endpoints.authProfile, data);

  /// Upload avatar (base64)
  static Future<ApiResponse> uploadAvatar(String base64Image) =>
      _client.post(Endpoints.authAvatar, {'image': base64Image});

  /// Xóa tài khoản
  static Future<ApiResponse> deleteAccount() =>
      _client.delete(Endpoints.authAccount);

  /// API Social / Users
  static Future<ApiResponse> toggleFollow(dynamic targetId) =>
      _client.post(Endpoints.userFollow(targetId), {});

  static Future<ApiResponse> getPublicProfile(dynamic userId) =>
      _client.get(Endpoints.userPublicProfile(userId));

  static Future<ApiResponse> getFollowers(dynamic userId) =>
      _client.get(Endpoints.userFollowers(userId));

  static Future<ApiResponse> getFollowing(dynamic userId) =>
      _client.get(Endpoints.userFollowing(userId));

  /// Check đã login chưa (local)
  static Future<bool> isLoggedIn() => TokenManager.isLoggedIn();

  /// Lấy user info đã cache
  static Future<Map<String, dynamic>?> getCachedUser() =>
      TokenManager.getUser();
}
