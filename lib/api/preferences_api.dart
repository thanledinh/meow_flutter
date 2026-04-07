import '../models/user_preferences.dart';
import 'api_client.dart';

class PreferencesApi {
  static Future<UserPreferences?> getPreferences() async {
    try {
      final res = await ApiClient().get('/user/preferences');
      if (res.success && res.data != null && res.data['data'] != null) {
        return UserPreferences.fromJson(res.data['data']);
      }
      return null;
    } catch (e) {
      print('PreferencesApi.getPreferences Error: $e');
      return null;
    }
  }

  static Future<bool> updatePreferences(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient().put('/user/preferences', data);
      return res.success;
    } catch (e) {
      print('PreferencesApi.updatePreferences Error: $e');
      return false;
    }
  }
}
