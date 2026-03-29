import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static const String _userNameKey = 'user_name';

  String? _cachedUserName;

  Future<void> saveRegisteredName(String name) async {
    final String normalizedName = name.trim();
    if (normalizedName.isEmpty) return;
    _cachedUserName = normalizedName;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userNameKey, normalizedName);
  }

  Future<String?> getRegisteredName() async {
    if (_cachedUserName != null) return _cachedUserName;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _cachedUserName = preferences.getString(_userNameKey);
    return _cachedUserName;
  }
}
