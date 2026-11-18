import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small JSON key-value store on top of SharedPreferences.
/// Used by mock repositories (Phase 1) and for non-sensitive app settings.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const String prefix = 'fasal.';

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString('$prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null; // corrupted value — ignore rather than crash
    }
  }

  List<Map<String, dynamic>>? readList(String key) {
    final raw = _prefs.getString('$prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Object value) => _prefs.setString('$prefix$key', jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove('$prefix$key');

  /// Removes every FASAL key (used by "Restart demo").
  Future<void> clearAll() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith(prefix)).toList()) {
      await _prefs.remove(k);
    }
  }
}
