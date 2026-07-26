import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = "auth_token";
  static const String _roleKey = "user_role";
  static const String _loginTimeKey = "login_time";

  // ✅ SAVE TOKEN + ROLE + TIME
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.toLowerCase());
  }

  // ✅ GETTERS
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // ✅ SESSION EXPIRY CHECK (UX Friendly)
  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);

    if (loginTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - loginTime;

    const int sessionDuration = 259200000; // Example: 3 Days
    return difference > sessionDuration;
  }

  // ✅ LOGOUT ACTIONS
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_loginTimeKey);
    // Role is intentionally kept to remember user selection on the login screen
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_loginTimeKey);
  }
}