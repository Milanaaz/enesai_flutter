import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiChatService {
  GeminiChatService._()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  static final GeminiChatService instance = GeminiChatService._();

  static const String _defineApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const String _storageKey = 'gemini_api_key';

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isConfigured() async => (await _apiKey()).isNotEmpty;

  Future<void> saveApiKey(String apiKey) async {
    final String normalized = apiKey.trim();
    if (normalized.isEmpty) {
      throw const GeminiChatException('Введите Gemini API key');
    }
    await _storage.write(key: _storageKey, value: normalized);
  }

  Future<String> sendMessage(List<GeminiChatMessage> messages) async {
    final String apiKey = await _apiKey();
    if (apiKey.isEmpty) {
      throw const GeminiChatException(
        'Gemini API key не настроен. Нажмите на значок ключа сверху и сохраните ключ.',
      );
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/models/$_model:generateContent',
        options: Options(headers: <String, dynamic>{'x-goog-api-key': apiKey}),
        data: <String, dynamic>{
          'systemInstruction': <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{
                'text':
                    'Ты дружелюбный ИИ-помощник в приложении для изучения кыргызского языка. '
                    'Отвечай кратко и понятно. Если пользователь просит практику, давай примеры на кыргызском '
                    'с русским объяснением. Не выдумывай прогресс пользователя.',
              },
            ],
          },
          'contents': messages.map((GeminiChatMessage message) {
            return <String, dynamic>{
              'role': message.isUser ? 'user' : 'model',
              'parts': <Map<String, String>>[
                <String, String>{'text': message.text},
              ],
            };
          }).toList(),
          'generationConfig': <String, dynamic>{
            'temperature': 0.7,
            'maxOutputTokens': 700,
          },
        },
      );

      final String reply = _extractText(response.data).trim();
      if (reply.isEmpty) {
        throw const GeminiChatException('Gemini вернул пустой ответ');
      }
      return reply;
    } on DioException catch (error) {
      throw GeminiChatException(_extractErrorMessage(error));
    }
  }

  Future<String> _apiKey() async {
    if (_defineApiKey.trim().isNotEmpty) return _defineApiKey.trim();
    return (await _storage.read(key: _storageKey) ?? '').trim();
  }

  String _extractText(dynamic payload) {
    if (payload is! Map<String, dynamic>) return '';
    final dynamic candidates = payload['candidates'];
    if (candidates is! List<dynamic> || candidates.isEmpty) return '';
    final dynamic firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) return '';
    final dynamic content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) return '';
    final dynamic parts = content['parts'];
    if (parts is! List<dynamic>) return '';

    return parts
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> part) => (part['text'] ?? '').toString())
        .where((String text) => text.trim().isNotEmpty)
        .join('\n');
  }

  String _extractErrorMessage(DioException error) {
    final dynamic responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic errorData = responseData['error'];
      if (errorData is Map<String, dynamic>) {
        final dynamic message = errorData['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Gemini долго отвечает. Попробуйте еще раз.';
    }
    return error.message?.trim().isNotEmpty == true
        ? error.message!.trim()
        : 'Не удалось получить ответ Gemini';
  }
}

class GeminiChatMessage {
  const GeminiChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class GeminiChatException implements Exception {
  const GeminiChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
