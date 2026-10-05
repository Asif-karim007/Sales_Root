import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:salesroot/core/network/api_extras.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/debug_log.dart';

/// Strips null query params and attaches the session token and workspace.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.token, required this.workspaceId});

  final String? Function() token;
  final int? Function() workspaceId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters.removeWhere((_, value) => value == null);
    final bearer = token();
    if (bearer != null && bearer.isNotEmpty) {
      options.headers['Authorization'] =
          'Bearer ${Uri.encodeComponent(bearer)}';
    }
    final workspace = workspaceId();
    if (workspace != null) {
      options.headers[ApiConfig.workspaceHeader] = '$workspace';
    }
    handler.next(options);
  }
}

class LogInterceptor extends Interceptor {
  static const _redacted = '<redacted>';
  static const _sensitive = {
    'authorization',
    'token',
    'password',
    'secret',
    'apikey',
    'accesskey',
    'privatekey',
    'credential',
    'otp',
    'pin',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(options);
    logDebug('API request: ${options.method} ${options.uri}');
    final data = options.data;
    if (data != null && data is! FormData) {
      logDebug('API parameters: ${logPreview(_sanitize(data))}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logDebug('API response: ${response.statusCode}');
    handler.next(response);
  }

  Object? _sanitize(Object? value, {String? key}) {
    if (key != null && _isSensitive(key)) return _redacted;
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), _sanitize(v, key: k.toString())),
      );
    }
    if (value is Iterable) return value.map(_sanitize).toList();
    return value;
  }

  bool _isSensitive(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return _sensitive.any(normalized.contains);
  }
}

/// The API answers with a real status code and a plain JSON body. A 2xx
/// passes through; anything else raises [ApiFailure] from the
/// `{code, message: {bn, en}, field}` error body.
class StatusInterceptor extends Interceptor {
  StatusInterceptor({required this.onSessionExpired, required this.bangla});

  final void Function() onSessionExpired;
  final bool Function() bangla;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return handler.next(response);

    final error = _decode(response.data);
    final message = _message(
      error is Map ? error[ApiConfig.errorMessage] : null,
    );
    final field = error is Map ? error[ApiConfig.errorField] : null;
    if (status == 401 &&
        response.requestOptions.headers.containsKey('Authorization')) {
      onSessionExpired();
    }
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: ApiFailure(
          status,
          message.isEmpty ? _fallbackMessage(status) : message,
          fieldErrors: field is String && message.isNotEmpty
              ? {field: message}
              : const {},
          code: error is Map ? error[ApiConfig.errorCode] as String? : null,
        ),
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiFailure) return handler.next(err);
    handler.next(err.copyWith(error: ApiFailure(0, _transportMessage(err))));
  }

  dynamic _decode(dynamic body) {
    if (body is! List<int>) return body;
    try {
      return jsonDecode(utf8.decode(body));
    } on FormatException {
      return null;
    }
  }

  String _message(dynamic message) {
    if (message is Map) {
      return '${message[bangla() ? 'bn' : 'en'] ?? message['en'] ?? ''}';
    }
    return message is String ? message : '';
  }

  String _fallbackMessage(int status) => switch (status) {
    401 => 'Your session has expired. Please sign in again.',
    403 => 'You do not have permission to do that.',
    404 => 'This record is no longer available.',
    500 => 'Something went wrong. Please try again.',
    _ => 'Request failed with status $status.',
  };

  String _transportMessage(DioException err) => switch (err.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'The request timed out. Please try again.',
    DioExceptionType.connectionError => 'No Internet connection',
    _ when err.error is SocketException => 'No Internet connection',
    _ => err.message ?? 'Network error',
  };
}
