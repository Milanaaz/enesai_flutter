import 'package:dio/dio.dart';
import 'package:dipl/features/personalization/data/placement_test_models.dart';
import 'package:dipl/services/auth_service.dart';

class PlacementTestService {
  PlacementTestService._()
    : _dio = Dio(
        BaseOptions(
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

  static final PlacementTestService instance = PlacementTestService._();

  final Dio _dio;

  Future<PlacementTest> getActiveTest() async {
    try {
      final Response<dynamic> response = await _requestWithRetry(
        () async => _dio.get<dynamic>(
          '/api/v1/placement-test',
          options: await _authOptions(),
        ),
      );
      final Map<String, dynamic> data = _extractData(response.data);
      return PlacementTest.fromJson(data);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<PlacementTestResult> submitAnswers({
    required String testId,
    required List<PlacementAnswer> answers,
  }) async {
    try {
      final Response<dynamic> response = await _requestWithRetry(
        () async => _dio.post<dynamic>(
          '/api/v1/placement-test/submit',
          data: <String, dynamic>{
            'testId': testId,
            'answers': answers.map((PlacementAnswer answer) {
              return answer.toJson();
            }).toList(),
          },
          options: await _authOptions(),
        ),
      );
      final Map<String, dynamic> data = _extractData(response.data);
      return PlacementTestResult.fromJson(data);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    }
  }

  Future<Options> _authOptions() async {
    final String? accessToken = await AuthService.instance.getAccessToken();
    if ((accessToken ?? '').trim().isEmpty) {
      throw const AuthException('Требуется вход в аккаунт');
    }
    return Options(
      headers: <String, dynamic>{
        'Authorization': 'Bearer ${accessToken!.trim()}',
      },
    );
  }

  Future<Response<dynamic>> _requestWithRetry(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (!_isTimeout(error)) rethrow;
      return request();
    }
  }

  Map<String, dynamic> _extractData(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      throw const AuthException('Unexpected server response');
    }
    final dynamic data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Missing placement test data in response');
    }
    return data;
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

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
}
