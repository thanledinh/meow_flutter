import 'package:flutter/material.dart';
import '../api/api_client.dart';

/// Auth Provider — replaces AuthContext.js
/// Quản lý trạng thái đăng nhập toàn app
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuth();
  }

  /// Check token on startup
  Future<void> checkAuth() async {
    try {
      final loggedIn = await TokenManager.isLoggedIn();
      if (loggedIn) {
        _user = await TokenManager.getUser();
        _isLoggedIn = true;
      } else {
        _user = null;
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gọi sau khi login/register thành công (token đã lưu trong AuthApi)
  Future<void> onLoginSuccess() async {
    _user = await TokenManager.getUser();
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Cập nhật user info locally (sau khi edit profile)
  void updateUser(Map<String, dynamic> updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Gọi khi logout
  Future<void> onLogout() async {
    await TokenManager.clear();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
