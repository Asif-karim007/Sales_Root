import 'package:flutter/foundation.dart';

void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message, wrapWidth: 1024);
  }
}

String logPreview(Object? value, {int maxLength = 500}) {
  if (!kDebugMode) return '';
  final text = value?.toString() ?? 'null';
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}… '
      '[truncated, ${text.length} chars total]';
}
