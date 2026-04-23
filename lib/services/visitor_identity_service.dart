import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class VisitorIdentityService {
  static const _visitorIdKey = 'visitor_id';
  static const _visitorNameKey = 'visitor_display_name';

  static Future<String> getVisitorId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_visitorIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random();
    final randomSuffix = random.nextInt(1 << 30);
    final generated =
        'visitor_${DateTime.now().microsecondsSinceEpoch}_$randomSuffix';
    await prefs.setString(_visitorIdKey, generated);
    return generated;
  }

  static Future<String?> getVisitorDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_visitorNameKey)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> saveVisitorDisplayName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_visitorNameKey);
      return;
    }
    await prefs.setString(_visitorNameKey, trimmed);
  }
}
