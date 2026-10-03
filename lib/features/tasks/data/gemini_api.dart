import 'package:dio/dio.dart';

/// Google's Gemini API on its own [Dio], so no SalesRoot session or workspace
/// header ever reaches Google. The key comes from
/// `--dart-define-from-file=secrets.json`.
class GeminiApi {
  GeminiApi({Dio? dio}) : _dio = dio ?? _build();

  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final Dio _dio;

  static Dio _build() => Dio(
    BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
      headers: {'x-goog-api-key': apiKey},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  Future<Map<String, dynamic>> generateContent(
    String model,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'models/$model:generateContent',
      data: body,
    );
    return response.data ?? const {};
  }
}
