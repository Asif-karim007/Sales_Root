/// Per-request switches and the API constants that arrive with the backend.
abstract final class ApiExtras {
  /// Hand the whole `{IsSuccess, Message, Result}` body to the model instead
  /// of unwrapping `Result`.
  static const String keepEnvelope = 'keepEnvelope';
}

abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.salesrootcrm.com/api/v1',
  );
  static const String workspaceHeader = 'X-Workspace-Id';
  static const String envelopeResult = 'Result';
  static const String envelopeMessage = 'Message';
  static const String envelopeErrors = 'Errors';
  static const Duration timeout = Duration(seconds: 60);
}
