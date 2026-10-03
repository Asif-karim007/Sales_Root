import 'package:flutter/widgets.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/l10n/l10n.dart';

/// A one-line explanation of [error] for a snackbar.
String supportFailureText(BuildContext context, Object? error) {
  final l10n = context.l10n;
  if (error is! ApiFailure) return l10n.errorGeneric;
  if (error.isOffline) return l10n.errorOffline;
  if (error.isForbidden) return l10n.errorForbidden;
  if (error.isNotFound) return l10n.errorNotFound;
  final message = error.message.trim();
  return error.isValidation && message.isNotEmpty ? message : l10n.errorGeneric;
}

/// The server's message for [field] when [error] is a validation failure.
String? supportFieldError(Object? error, String field) =>
    error is ApiFailure ? error.fieldError(field) : null;
