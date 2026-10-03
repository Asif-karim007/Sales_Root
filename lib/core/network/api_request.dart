import 'package:dio/dio.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/debug_log.dart';

/// Runs one API call and rethrows any failure as [ApiFailure], so screens can
/// switch on the status code.
Future<T> apiRequest<T>(String label, Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    final failure = error.error;
    logDebug('$label failed: $failure');
    throw failure is ApiFailure
        ? failure
        : ApiFailure(error.response?.statusCode ?? 0, error.message ?? '');
  }
}
