import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../services/mqtt_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';

/// Auth Provider — replaces AuthContext.js
/// Quản lý trạng thái đăng nhập toàn app
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _bootstrapData;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get bootstrapData => _bootstrapData;
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuth();
  }

  Future<void> fetchBootstrap() async {
    try {
      final res = await ApiClient().get('/api/app/bootstrap');
      if (res.success && res.data != null) {
        _bootstrapData = (res.data as Map?)?['data'];
      }
    } catch (_) {}
  }

  /// Check token on startup
  Future<void> checkAuth() async {
    try {
      final loggedIn = await TokenManager.isLoggedIn();
      if (loggedIn) {
        _user = await TokenManager.getUser();
        _isLoggedIn = true;
        await fetchBootstrap();
      } else {
        _user = null;
        _isLoggedIn = false;
        _bootstrapData = null;
      }
    } catch (e) {
      _isLoggedIn = false;
      _user = null;
      _bootstrapData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gọi sau khi login/register thành công (token đã lưu trong AuthApi)
  Future<void> onLoginSuccess() async {
    _user = await TokenManager.getUser();
    _isLoggedIn = true;
    await fetchBootstrap();
    notifyListeners();
    // Kết nối MQTT — field 'id' trong user object chính là Firebase UID
    final userId = _user?['id']?.toString();
    if (userId != null) {
      MqttService().connect(userId);
    }
  }

  /// Cập nhật user info locally (sau khi edit profile)
  void updateUser(Map<String, dynamic> updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Gọi khi logout
  Future<void> onLogout() async {
    MqttService().disconnect(); // Ngắt MQTT trước
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await TokenManager.clear();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
