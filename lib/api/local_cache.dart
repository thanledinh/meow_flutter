import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for API responses — enables offline viewing.
/// Uses SharedPreferences to store JSON responses keyed by endpoint.
class LocalCache {
  static const String _prefix = '@moew_cache_';

  /// Save a response body for the given endpoint
  static Future<void> save(String endpoint, String responseBody) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$endpoint', responseBody);
  }

  /// Load cached response for the given endpoint
  /// Returns parsed Map if cache exists, null otherwise
  static Future<Map<String, dynamic>?> load(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$endpoint');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear all cached data (call on logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
