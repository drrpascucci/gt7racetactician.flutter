import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_config_service.dart';

class SharedPreferencesAppConfigStore implements AppConfigStore {
  static const String _key = 'gt7_app_config';

  @override
  Future<Map<String, Object?>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
      return Map<String, Object?>.from(decoded as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Map<String, Object?> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }
}
