import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import '../api/preferences_api.dart';
import '../config/theme.dart';

class PreferencesProvider extends ChangeNotifier {
  UserPreferences _prefs = UserPreferences(); // Default sakura
  UserPreferences get prefs => _prefs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PreferencesProvider() {
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final sp = await SharedPreferences.getInstance();
    final localData = sp.getString('user_prefs');
    if (localData != null) {
      try {
        _prefs = UserPreferences.fromJson(jsonDecode(localData));
        _applyThemeToGlobal(_prefs.presetTheme);
        notifyListeners();
      } catch (e) {
        print('Error parsing local prefs: $e');
      }
    }
  }

  Future<void> saveLocal(UserPreferences data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_prefs', jsonEncode(data.toJson()));
  }

  // Called in app startup (e.g., after login or in main shell)
  Future<void> fetchFromApi() async {
    _isLoading = true;
    notifyListeners();

    final data = await PreferencesApi.getPreferences();
    if (data != null) {
      _prefs = data;
      await saveLocal(_prefs);
      _applyThemeToGlobal(_prefs.presetTheme);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void _applyThemeToGlobal(String presetName) {
    MoewColors.applyPreset(presetName);
  }

  // Update theme preset
  Future<void> setThemePreset(String preset) async {
    if (_prefs.presetTheme == preset) return;

    // Optimistic UI update
    _prefs = _prefs.copyWith(presetTheme: preset);
    _applyThemeToGlobal(preset);
    await saveLocal(_prefs);
    notifyListeners();

    // Background sync
    await PreferencesApi.updatePreferences({'presetTheme': preset});
  }

  // Toggle notification
  Future<void> toggleNotification(String key, bool value) async {
    Map<String, dynamic> update = {};
    if (key == 'notifyFeeding') {
      _prefs = _prefs.copyWith(notifyFeeding: value);
      update = {'notifyFeeding': value};
    } else if (key == 'notifyHealth') {
      _prefs = _prefs.copyWith(notifyHealth: value);
      update = {'notifyHealth': value};
    } else if (key == 'notifySocial') {
      _prefs = _prefs.copyWith(notifySocial: value);
      update = {'notifySocial': value};
    } else if (key == 'notifyBooking') {
      _prefs = _prefs.copyWith(notifyBooking: value);
      update = {'notifyBooking': value};
    }
    
    await saveLocal(_prefs);
    notifyListeners();

    await PreferencesApi.updatePreferences(update);
  }
}
