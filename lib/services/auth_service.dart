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
  static const String _userLevelKey = 'auth_user_level';
  static const String _userGoalTypeKey = 'auth_user_goal_type';

  final Dio _dio;

  String? _cachedUserName;
  String? _cachedUserEmail;
  String? _cachedUserLevel;
  String? _cachedUserGoalType;

  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final Response<dynamic> response =
          await _postWithRetry('/api/v1/auth/register', <String, dynamic>{
            'email': email.trim(),
            'password': password,
            'firstName': firstName.trim(),
            'lastName': lastName.trim(),
          });
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
        <String, dynamic>{'email': email.trim(), 'password': password},
      );
      return _handleAuthResponse(response.data);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _postWithRetry('/api/v1/auth/forgot-password', <String, dynamic>{
        'email': email.trim(),
      });
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await _dio.get<dynamic>(
        '/api/v1/auth/verify-reset-code',
        queryParameters: <String, dynamic>{
          'email': email.trim(),
          'code': code.trim(),
        },
      );
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _postWithRetry('/api/v1/auth/reset-password', <String, dynamic>{
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      });
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

  Future<void> updateOnboardingProfile({
    required String languageLevel,
    required String goalType,
  }) async {
    final String normalizedLevel = languageLevel.trim().toUpperCase();
    final String normalizedGoalType = goalType.trim().toUpperCase();
    if (normalizedLevel.isEmpty || normalizedGoalType.isEmpty) {
      throw const AuthException('Некорректные данные уровня или цели');
    }

    final String? accessToken = await getAccessToken();
    if ((accessToken ?? '').trim().isEmpty) {
      throw const AuthException('Требуется вход в аккаунт');
    }

    try {
      await _putWithRetry(
        '/api/v1/users/me',
        <String, dynamic>{
          'languageLevel': normalizedLevel,
          'goalType': normalizedGoalType,
        },
        options: Options(
          method: 'PUT',
          headers: <String, dynamic>{
            'Authorization': 'Bearer ${accessToken!.trim()}',
          },
        ),
      );
      await saveSelectedLevel(normalizedLevel);
      await saveGoalType(normalizedGoalType);
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
    final String? accessToken = await getAccessToken();
    if ((accessToken ?? '').trim().isNotEmpty) {
      try {
        await _postWithRetry(
          '/api/v1/auth/logout',
          const <String, dynamic>{},
          options: Options(
            headers: <String, dynamic>{
              'Authorization': 'Bearer ${accessToken!.trim()}',
            },
          ),
        );
      } on DioException {
        // Local token cleanup below is still required even if server logout fails.
      }
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
    await preferences.remove(_userLevelKey);
    await preferences.remove(_userGoalTypeKey);
    _cachedUserName = null;
    _cachedUserEmail = null;
    _cachedUserLevel = null;
    _cachedUserGoalType = null;
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

  Future<void> saveSelectedLevel(String level) async {
    final String normalizedLevel = level.trim().toUpperCase();
    if (normalizedLevel.isEmpty) return;
    _cachedUserLevel = normalizedLevel;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userLevelKey, normalizedLevel);
  }

  Future<String?> getSelectedLevel() async {
    if (_cachedUserLevel != null) return _cachedUserLevel;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _cachedUserLevel = preferences.getString(_userLevelKey);
    return _cachedUserLevel;
  }

  Future<void> saveGoalType(String goalType) async {
    final String normalizedGoalType = goalType.trim().toUpperCase();
    if (normalizedGoalType.isEmpty) return;
    _cachedUserGoalType = normalizedGoalType;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userGoalTypeKey, normalizedGoalType);
  }

  Future<String?> getGoalType() async {
    if (_cachedUserGoalType != null) return _cachedUserGoalType;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _cachedUserGoalType = preferences.getString(_userGoalTypeKey);
    return _cachedUserGoalType;
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
    final String languageLevel = (userMap['languageLevel'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final String goalType = (userMap['goalType'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

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
    if (languageLevel.isNotEmpty) {
      _cachedUserLevel = languageLevel;
      await preferences.setString(_userLevelKey, languageLevel);
    }
    if (goalType.isNotEmpty) {
      _cachedUserGoalType = goalType;
      await preferences.setString(_userGoalTypeKey, goalType);
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
    if (_isConnectionBlocked(error)) {
      return 'Не удалось подключиться к серверу. Проверьте, что backend запущен и разрешает запросы с этого сайта.';
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
    Map<String, dynamic> data, {
    Options? options,
  }) async {
    try {
      return await _dio.post<dynamic>(path, data: data, options: options);
    } on DioException catch (error) {
      if (!_isTimeout(error)) rethrow;
      return _dio.post<dynamic>(path, data: data, options: options);
    }
  }

  Future<Response<dynamic>> _putWithRetry(
    String path,
    Map<String, dynamic> data, {
    Options? options,
  }) async {
    try {
      return await _dio.put<dynamic>(path, data: data, options: options);
    } on DioException catch (error) {
      if (!_isTimeout(error)) rethrow;
      return _dio.put<dynamic>(path, data: data, options: options);
    }
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  bool _isConnectionBlocked(DioException error) {
    final String message = error.message ?? '';
    return error.response == null &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.unknown ||
            message.contains('XMLHttpRequest') ||
            message.contains('onError'));
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
    if (parts.length == 2 && parts[0].toLowerCase() == parts[1].toLowerCase()) {
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
