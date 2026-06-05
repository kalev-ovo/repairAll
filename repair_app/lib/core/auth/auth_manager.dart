import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String?> getToken() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(_tokenKey);
  }

  Future<void> saveAuth({
    required String token,
    required String role,
    required int userId,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_tokenKey, token);
    await _prefs!.setString(_roleKey, role);
    await _prefs!.setInt(_userIdKey, userId);
  }

  String? getRole() => _prefs?.getString(_roleKey);

  int? getUserId() => _prefs?.getInt(_userIdKey);

  Future<bool> isLoggedIn() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.containsKey(_tokenKey);
  }

  Future<void> logout() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_roleKey);
    await _prefs!.remove(_userIdKey);
  }
}
