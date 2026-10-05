abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://salesroot-api.salebee.net/v1/',
  );
  static const String errorCode = 'code';
  static const String errorMessage = 'message';
  static const String errorField = 'field';
  static const Duration timeout = Duration(seconds: 60);
}
