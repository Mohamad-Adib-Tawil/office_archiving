import 'package:shared_preferences/shared_preferences.dart';

class FirstOpenService {
  static const String _prefix = 'first_open:';

  static Future<bool> isFirstOpen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '$_prefix$key';
    final seen = prefs.getBool(fullKey) ?? false;
    if (!seen) {
      await prefs.setBool(fullKey, true);
      return true;
    }
    return false;
  }

  static Future<void> reset(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  static Future<void> resetAll(Iterable<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      await prefs.remove('$_prefix$key');
    }
  }
}
