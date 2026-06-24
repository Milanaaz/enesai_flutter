import 'package:dio/dio.dart';
import 'package:dipl/features/dictionary/presentation/models/dictionary_word.dart';
import 'package:dipl/services/auth_service.dart';

class DictionaryApiService {
  DictionaryApiService._()
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

  static final DictionaryApiService instance = DictionaryApiService._();

  final Dio _dio;

  Future<List<DictionaryWord>> getMyDictionary({String? status}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/dictionary',
        queryParameters: <String, dynamic>{
          if ((status ?? '').isNotEmpty) 'status': status,
        },
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => DictionaryWord.fromUserJson(_asMap(item)))
          .where((DictionaryWord word) => word.kyrgyz.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<DictionaryStats> getStats() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/dictionary/stats',
        options: await _authorizedOptions(),
      );
      return DictionaryStats.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<List<DictionaryWord>> searchGlobalWords({
    String search = '',
    String? level,
    String? topic,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/words',
        queryParameters: <String, dynamic>{
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if ((level ?? '').isNotEmpty) 'level': level,
          if ((topic ?? '').isNotEmpty) 'topic': topic,
          'page': 0,
          'size': 30,
        },
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => DictionaryWord.fromGlobalJson(_asMap(item)))
          .where((DictionaryWord word) => word.kyrgyz.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<DictionaryWord> getWord(String wordId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/words/$wordId',
        options: await _authorizedOptions(),
      );
      return DictionaryWord.fromGlobalJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<DictionaryWord> addWord(String wordId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/dictionary',
        data: <String, dynamic>{'wordId': wordId},
        options: await _authorizedOptions(),
      );
      return DictionaryWord.fromUserJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<void> removeWord(String userWordId) async {
    try {
      await _dio.delete<dynamic>(
        '/api/v1/dictionary/words/$userWordId',
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<DictionaryWord> updateStatus({
    required String userWordId,
    required WordStatus status,
  }) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '/api/v1/dictionary/words/$userWordId/status',
        data: <String, dynamic>{'status': wordStatusToApi(status)},
        options: await _authorizedOptions(),
      );
      return DictionaryWord.fromUserJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<List<DictionaryWord>> getReviewWords() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/dictionary/review',
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => DictionaryWord.fromUserJson(_asMap(item)))
          .where((DictionaryWord word) => word.kyrgyz.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
    }
  }

  Future<DictionaryWord> submitReview({
    required String userWordId,
    required bool knew,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/dictionary/review',
        data: <String, dynamic>{'userWordId': userWordId, 'knew': knew},
        options: await _authorizedOptions(),
      );
      return DictionaryWord.fromUserJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw DictionaryApiException(_extractErrorMessage(error));
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
    return const <dynamic>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  String _extractErrorMessage(DioException error) {
    final dynamic responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }
    return 'Не удалось загрузить словарь';
  }
}

class DictionaryStats {
  const DictionaryStats({
    required this.totalWords,
    required this.learningWords,
    required this.learnedWords,
    required this.favoriteWords,
    required this.difficultWords,
    required this.dueForReviewToday,
  });

  factory DictionaryStats.fromJson(Map<String, dynamic> json) {
    return DictionaryStats(
      totalWords: _asInt(json['totalWords']),
      learningWords: _asInt(json['learningWords']),
      learnedWords: _asInt(json['learnedWords']),
      favoriteWords: _asInt(json['favoriteWords']),
      difficultWords: _asInt(json['difficultWords']),
      dueForReviewToday: _asInt(json['dueForReviewToday']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  final int totalWords;
  final int learningWords;
  final int learnedWords;
  final int favoriteWords;
  final int difficultWords;
  final int dueForReviewToday;
}

class DictionaryApiException implements Exception {
  const DictionaryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
