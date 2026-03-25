import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'local_cache.dart';

// ═══════════════════════════════════════════
// CẤU HÌNH
// ═══════════════════════════════════════════
class ApiConfig {
  static const String baseUrl = 'http://171.248.184.99:3000/api';
  static const Duration timeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 30);
}

// ═══════════════════════════════════════════
// API RESPONSE MODEL
// ═══════════════════════════════════════════
class ApiResponse {
  final bool success;
  final dynamic data;
  final int status;
  final String? error;
  final bool fromCache;

  ApiResponse({
    required this.success,
    this.data,
    required this.status,
    this.error,
    this.fromCache = false,
  });
}

// ═══════════════════════════════════════════
// TOKEN MANAGER
// ═══════════════════════════════════════════
class TokenManager {
  static const String _tokenKey = '@moew_auth_token';
  static const String _userKey = '@moew_auth_user';

  static Future<void> save(String token, Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw != null) {
      return jsonDecode(raw) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

// ═══════════════════════════════════════════
// 401 HANDLER
// ═══════════════════════════════════════════
typedef OnUnauthorizedCallback = void Function();

// ═══════════════════════════════════════════
// API CLIENT
// ═══════════════════════════════════════════
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  OnUnauthorizedCallback? _onUnauthorized;
  bool _isHandling401 = false;

  void setOnUnauthorized(OnUnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }

  void _handle401() {
    if (_isHandling401) return;
    _isHandling401 = true;
    TokenManager.clear();
    LocalCache.clear(); // Clear offline cache on logout
    _onUnauthorized?.call();
    Future.delayed(const Duration(seconds: 3), () {
      _isHandling401 = false;
    });
  }

  // ─── Core Request ──────────────────────
  Future<ApiResponse> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool auth = true,
    Duration? timeout,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (auth) {
      final token = await TokenManager.getToken();
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    try {
      http.Response response;
      final requestTimeout = timeout ?? ApiConfig.timeout;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http
              .post(url,
                  headers: requestHeaders,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(requestTimeout);
          break;
        case 'PUT':
          response = await http
              .put(url,
                  headers: requestHeaders,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(url,
                  headers: requestHeaders,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(requestTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: requestHeaders)
              .timeout(requestTimeout);
          break;
        default:
          response = await http
              .get(url, headers: requestHeaders)
              .timeout(requestTimeout);
      }

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        responseData = null;
      }

      // ─── DEBUG LOG ───
      debugPrint('┌── API $method $endpoint');
      debugPrint('│ Status: ${response.statusCode}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...[truncated]'
          : response.body;
      debugPrint('│ Body: $bodyPreview');
      debugPrint('└──────────────────────────');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          responseData?['success'] != false) {
        // Cache successful GET responses for offline use
        if (method.toUpperCase() == 'GET') {
          LocalCache.save(endpoint, response.body);
        }
        return ApiResponse(
          success: true,
          data: responseData,
          status: response.statusCode,
        );
      }

      if (response.statusCode == 401) {
        _handle401();
      }

      return ApiResponse(
        success: false,
        status: response.statusCode,
        error:
            responseData?['message'] ?? 'Lỗi server: ${response.statusCode}',
      );
    } on TimeoutException {
      // Try cache on timeout (GET only)
      if (method.toUpperCase() == 'GET') {
        final cached = await LocalCache.load(endpoint);
        if (cached != null) {
          debugPrint('⚡ Cache hit (timeout): $endpoint');
          return ApiResponse(success: true, data: cached, status: 200, fromCache: true);
        }
      }
      return ApiResponse(
        success: false,
        status: 0,
        error: 'Request timeout — kiểm tra kết nối mạng.',
      );
    } catch (e) {
      // Try cache on network error (GET only)
      if (method.toUpperCase() == 'GET') {
        final cached = await LocalCache.load(endpoint);
        if (cached != null) {
          debugPrint('⚡ Cache hit (offline): $endpoint');
          return ApiResponse(success: true, data: cached, status: 200, fromCache: true);
        }
      }
      return ApiResponse(
        success: false,
        status: 0,
        error: e.toString(),
      );
    }
  }

  // ─── Upload (multipart) ────────────────
  Future<ApiResponse> upload(
    String endpoint,
    String filePath, {
    String fieldName = 'image',
    bool auth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);

    if (auth) {
      final token = await TokenManager.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    try {
      final streamedResponse =
          await request.send().timeout(ApiConfig.uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        responseData = null;
      }

      if (response.statusCode == 401) {
        _handle401();
      }

      return ApiResponse(
        success: response.statusCode >= 200 &&
            response.statusCode < 300 &&
            responseData?['success'] != false,
        data: responseData,
        status: response.statusCode,
        error: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : (responseData?['message'] ?? 'Upload thất bại'),
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        status: 0,
        error: 'Upload timeout (30s)',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        status: 0,
        error: e.toString(),
      );
    }
  }

  // ─── Shortcut Methods ─────────────────
  Future<ApiResponse> get(String endpoint,
          {bool auth = true, Map<String, String>? headers}) =>
      request(endpoint, method: 'GET', auth: auth, headers: headers);

  Future<ApiResponse> post(String endpoint, Map<String, dynamic>? body,
          {bool auth = true, Map<String, String>? headers}) =>
      request(endpoint, method: 'POST', body: body, auth: auth, headers: headers);

  Future<ApiResponse> put(String endpoint, Map<String, dynamic>? body,
          {bool auth = true, Map<String, String>? headers}) =>
      request(endpoint, method: 'PUT', body: body, auth: auth, headers: headers);

  Future<ApiResponse> patch(String endpoint, Map<String, dynamic>? body,
          {bool auth = true}) =>
      request(endpoint, method: 'PATCH', body: body, auth: auth);

  Future<ApiResponse> delete(String endpoint, {bool auth = true}) =>
      request(endpoint, method: 'DELETE', auth: auth);
}
