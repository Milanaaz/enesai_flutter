import 'package:dio/dio.dart';
import 'package:dipl/features/library/data/library_models.dart';
import 'package:dipl/services/auth_service.dart';

class LibraryApiService {
  LibraryApiService._()
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

  static final LibraryApiService instance = LibraryApiService._();

  final Dio _dio;

  Future<List<LibraryBook>> getCatalog({
    String search = '',
    String? level,
    String? genre,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/books',
        queryParameters: <String, dynamic>{
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if ((level ?? '').isNotEmpty) 'level': level,
          if ((genre ?? '').isNotEmpty) 'genre': genre,
          'page': 0,
          'size': 30,
        },
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => LibraryBook.fromJson(_asMap(item)))
          .where((LibraryBook book) => book.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw LibraryApiException(_extractErrorMessage(error));
    }
  }

  Future<List<LibraryBook>> getMyBooks() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/my-books',
        options: await _authorizedOptions(),
      );
      return _extractList(response.data)
          .map((dynamic item) => LibraryBook.fromJson(_asMap(item)))
          .where((LibraryBook book) => book.id.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw LibraryApiException(_extractErrorMessage(error));
    }
  }

  Future<LibraryBook> getBook(String bookId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/books/$bookId',
        options: await _authorizedOptions(),
      );
      return LibraryBook.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw LibraryApiException(_extractErrorMessage(error));
    }
  }

  Future<LibraryBookPage> getPage({
    required String bookId,
    required int pageNumber,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/books/$bookId/pages/$pageNumber',
        options: await _authorizedOptions(),
      );
      return LibraryBookPage.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw LibraryApiException(_extractErrorMessage(error));
    }
  }

  Future<void> updateProgress({
    required String bookId,
    required int currentPage,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/api/v1/books/progress',
        data: <String, dynamic>{'bookId': bookId, 'currentPage': currentPage},
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw LibraryApiException(_extractErrorMessage(error));
    }
  }

  Future<WordTranslation> translateWord(String word) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/books/translate',
        queryParameters: <String, dynamic>{'word': word},
        options: await _authorizedOptions(),
      );
      return WordTranslation.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw LibraryApiException(_extractErrorMessage(error));
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
    return 'Не удалось загрузить библиотеку';
  }
}

class LibraryApiException implements Exception {
  const LibraryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
