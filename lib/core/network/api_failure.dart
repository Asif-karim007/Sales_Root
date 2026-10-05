import 'package:salesroot/widgets/sr_failure.dart';

/// A request that did not succeed. The status code decides what the screen
/// does; [message] is the server text to show.
class ApiFailure implements Exception, SrDisplayableFailure {
  const ApiFailure(
    this.statusCode,
    this.message, {
    this.fieldErrors = const {},
    this.quota,
    this.code,
  });

  @override
  final int statusCode;
  @override
  final String message;

  /// Validation messages keyed by the server field name.
  final Map<String, String> fieldErrors;

  /// The plan limit that was hit, for a 402.
  final QuotaKind? quota;

  /// The server's error code, such as `V-002`.
  final String? code;

  /// The request never reached the server: no connection, or it timed out.
  bool get isOffline => statusCode == 0;
  bool get isValidation => statusCode == 400 || statusCode == 422;
  bool get isUnauthorised => statusCode == 401;
  bool get isQuota => statusCode == 402;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isServerFault => statusCode >= 500;

  String? fieldError(String field) => fieldErrors[field];

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}

enum QuotaKind { users, records, storage, cardScans, smsCredits }
