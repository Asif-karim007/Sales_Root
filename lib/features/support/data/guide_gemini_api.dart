import 'package:dio/dio.dart';

/// Google's Gemini API on its own [Dio], so no SalesRoot session header
/// reaches Google. The key comes from `--dart-define-from-file=secrets.json`.
class GuideGeminiApi {
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
      headers: {'x-goog-api-key': apiKey},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
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
