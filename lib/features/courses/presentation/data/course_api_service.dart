import 'package:dio/dio.dart';
import 'package:dipl/features/courses/presentation/models/course_models.dart';
import 'package:dipl/services/auth_service.dart';

class CourseApiService {
  CourseApiService._()
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

  static final CourseApiService instance = CourseApiService._();

  final Dio _dio;

  Future<List<CourseInfo>> getCourses({
    String search = '',
    String? level,
    CourseType? type,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/courses',
        queryParameters: <String, dynamic>{
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if ((level ?? '').trim().isNotEmpty) 'level': level!.trim(),
          if (type != null) 'type': _courseTypeToApi(type),
          'page': page,
          'size': size,
        },
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => CourseInfo.fromJson(_asMap(item)))
          .where((CourseInfo course) => course.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<CourseInfo> getCourseDetail(String courseId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId',
        options: await _authorizedOptions(),
      );
      return CourseInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/courses/$courseId/enroll',
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<void> startLesson(String lessonId) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/lessons/$lessonId/start',
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<void> completeLesson({
    required String lessonId,
    required int exerciseScorePercent,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/lessons/complete',
        data: <String, dynamic>{
          'lessonId': lessonId,
          'exerciseScorePercent': exerciseScorePercent.clamp(0, 100),
        },
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<List<UserCourseProgress>> getMyCourses() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/my-courses',
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => UserCourseProgress.fromJson(_asMap(item)))
          .where((UserCourseProgress course) => course.courseId.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<List<ExerciseInfo>> getLessonExercises(String lessonId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/lessons/$lessonId/exercises',
        options: await _authorizedOptions(),
      );
      final Map<String, dynamic> data = _extractMap(response.data);
      final List<dynamic> items = data['exercises'] is List<dynamic>
          ? data['exercises'] as List<dynamic>
          : _extractList(response.data);
      return items
          .map((dynamic item) => ExerciseInfo.fromJson(_asMap(item)))
          .where((ExerciseInfo exercise) => exercise.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<TestInfo> getModuleTest(String moduleId) async {
    return _getTest('/api/v1/modules/$moduleId/test');
  }

  Future<TestInfo> getCourseTest(String courseId) async {
    return _getTest('/api/v1/courses/$courseId/test');
  }

  Future<int> submitTest({
    required String testId,
    required Map<String, String> selectedOptionIds,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/tests/submit',
        data: <String, dynamic>{
          'testId': testId,
          'answers': selectedOptionIds.entries
              .map(
                (MapEntry<String, String> entry) => <String, dynamic>{
                  'questionId': entry.key,
                  'selectedOptionId': entry.value,
                },
              )
              .toList(),
        },
        options: await _authorizedOptions(),
      );
      final Map<String, dynamic> data = _extractMap(response.data);
      return _asInt(data['scorePercent']);
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<List<TestAttemptInfo>> getMyTestAttempts(String testId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/tests/$testId/my-attempts',
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => TestAttemptInfo.fromJson(_asMap(item)))
          .where((TestAttemptInfo attempt) => attempt.attemptId.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<bool> submitExerciseAnswer({
    required String exerciseId,
    String? selectedOptionId,
    String? textAnswer,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/exercises/answer',
        data: <String, dynamic>{
          'exerciseId': exerciseId,
          if ((selectedOptionId ?? '').isNotEmpty)
            'selectedOptionId': selectedOptionId,
          if ((textAnswer ?? '').isNotEmpty) 'textAnswer': textAnswer,
        },
        options: await _authorizedOptions(),
      );
      final Map<String, dynamic> data = _extractMap(response.data);
      return data['correct'] == true;
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<TestInfo> _getTest(String path) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        options: await _authorizedOptions(),
      );
      return TestInfo.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw CourseApiException(_extractErrorMessage(error));
    }
  }

  Future<Options> _authorizedOptions() async {
    final String? accessToken = await AuthService.instance.getAccessToken();
    return Options(
      headers: <String, dynamic>{
        if ((accessToken ?? '').trim().isNotEmpty)
          'Authorization': 'Bearer ${accessToken!.trim()}',
      },
    );
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    final Map<String, dynamic> root = _asMap(payload);
    final dynamic data = root.containsKey('data') ? root['data'] : payload;
    return _asMap(data);
  }

  List<dynamic> _extractList(dynamic payload) {
    final dynamic data = _asMap(payload).containsKey('data')
        ? _asMap(payload)['data']
        : payload;
    if (data is List<dynamic>) return data;
    final Map<String, dynamic> map = _asMap(data);
    if (map['content'] is List<dynamic>) return map['content'] as List<dynamic>;
    if (map['items'] is List<dynamic>) return map['items'] as List<dynamic>;
    if (map['exercises'] is List<dynamic>) {
      return map['exercises'] as List<dynamic>;
    }
    return const <dynamic>[];
  }

  String _extractErrorMessage(DioException error) {
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
    return 'Не удалось загрузить данные курса';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  String _courseTypeToApi(CourseType type) {
    return switch (type) {
      CourseType.general => 'GENERAL',
      CourseType.ort => 'ORT',
      CourseType.speaking => 'CONVERSATIONAL',
      CourseType.business => 'BUSINESS',
      CourseType.grammar => 'GRAMMAR',
      CourseType.reading => 'READING',
      CourseType.pronunciation => 'PRONUNCIATION',
    };
  }
}

class CourseApiException implements Exception {
  const CourseApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
