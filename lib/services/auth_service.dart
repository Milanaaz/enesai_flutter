import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._()
    : _dio = Dio(
        BaseOptions(
          // Set with: flutter run --dart-define=API_BASE_URL=https://your-api-host
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://enesai-backend.onrender.com',
          ),
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  static final AuthService instance = AuthService._();

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';

  final Dio _dio;

  String? _cachedUserName;
  String? _cachedUserEmail;

  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final Response<dynamic> response = await _postWithRetry(
        '/api/v1/auth/register',
        <String, dynamic>{
          'email': email.trim(),
          'password': password,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
        },
      );
      return _handleAuthResponse(response.data);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _postWithRetry(
        '/api/v1/auth/login',
        <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      );
      return _handleAuthResponse(response.data);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _postWithRetry(
        '/api/v1/auth/forgot-password',
        <String, dynamic>{'email': email.trim()},
      );
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final String? accessToken = await getAccessToken();
      await _postWithRetry(
        '/api/v1/auth/change-password',
        <String, dynamic>{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(
          headers: <String, dynamic>{
            if ((accessToken ?? '').isNotEmpty)
              'Authorization': 'Bearer ${accessToken!.trim()}',
          },
        ),
      );
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> refreshToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? refreshToken = preferences.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('Refresh token is missing');
    }

    try {
      final Response<dynamic> response = await _postWithRetry(
        '/api/v1/auth/refresh',
        <String, dynamic>{'refreshToken': refreshToken},
      );
      await _handleAuthResponse(response.data);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
    _cachedUserName = null;
    _cachedUserEmail = null;
  }

  Future<void> saveRegisteredName(String name) async {
    final String normalizedName = _normalizeStoredName(name);
    if (normalizedName.isEmpty) return;
    _cachedUserName = normalizedName;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userNameKey, normalizedName);
  }

  Future<String?> getRegisteredName() async {
    if (_cachedUserName != null) return _cachedUserName;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? storedName = preferences.getString(_userNameKey);
    final String normalizedName = _normalizeStoredName(storedName ?? '');
    _cachedUserName = normalizedName.isEmpty ? null : normalizedName;
    if (storedName != null && storedName != _cachedUserName) {
      if (_cachedUserName == null) {
        await preferences.remove(_userNameKey);
      } else {
        await preferences.setString(_userNameKey, _cachedUserName!);
      }
    }
    return _cachedUserName;
  }

  Future<String?> getRegisteredEmail() async {
    if (_cachedUserEmail != null) return _cachedUserEmail;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _cachedUserEmail = preferences.getString(_userEmailKey);
    return _cachedUserEmail;
  }

  Future<String?> getAccessToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_accessTokenKey);
  }

  Future<AuthUser> _handleAuthResponse(dynamic payload) async {
    if (payload is! Map<String, dynamic>) {
      throw const AuthException('Unexpected server response');
    }
    final dynamic data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Missing auth data in response');
    }

    final String accessToken = (data['accessToken'] ?? '').toString();
    final String refreshToken = (data['refreshToken'] ?? '').toString();
    final Map<String, dynamic> userMap = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    final String firstName = (userMap['firstName'] ?? '').toString().trim();
    final String lastName = (userMap['lastName'] ?? '').toString().trim();
    final String fullName = _normalizeNameFromParts(firstName, lastName);
    final String email = (userMap['email'] ?? '').toString().trim();

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (accessToken.isNotEmpty) {
      await preferences.setString(_accessTokenKey, accessToken);
    }
    if (refreshToken.isNotEmpty) {
      await preferences.setString(_refreshTokenKey, refreshToken);
    }
    if (fullName.isNotEmpty) {
      _cachedUserName = fullName;
      await preferences.setString(_userNameKey, fullName);
    }
    if (email.isNotEmpty) {
      _cachedUserEmail = email;
      await preferences.setString(_userEmailKey, email);
    }

    return AuthUser(
      id: (userMap['id'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: (userMap['role'] ?? '').toString(),
    );
  }

  String _extractErrorMessage(DioException error) {
    if (_isTimeout(error)) {
      return 'Сервер долго отвечает. Попробуйте снова через 5-10 секунд.';
    }
    final dynamic responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }
    return 'Request failed';
  }

  Future<Response<dynamic>> _postWithRetry(
    String path,
    Map<String, dynamic> data,
    {Options? options}
  ) async {
    try {
      return await _dio.post<dynamic>(path, data: data, options: options);
    } on DioException catch (error) {
      if (!_isTimeout(error)) rethrow;
      return _dio.post<dynamic>(path, data: data, options: options);
    }
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  String _normalizeNameFromParts(String firstName, String lastName) {
    final String first = firstName.trim();
    final String last = lastName.trim();
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    if (first.toLowerCase() == last.toLowerCase()) return first;
    return '$first $last';
  }

  String _normalizeStoredName(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 2 &&
        parts[0].toLowerCase() == parts[1].toLowerCase()) {
      return parts[0];
    }
    return parts.join(' ');
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
