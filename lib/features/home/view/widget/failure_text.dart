import 'package:flutter/widgets.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/l10n/l10n.dart';

/// One line for a snackbar about [error].
String failureText(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! ApiFailure) return l10n.errorGeneric;
  if (error.isOffline) return l10n.errorOffline;
  if (error.isForbidden) return l10n.errorForbidden;
  return error.message.trim().isEmpty ? l10n.errorGeneric : error.message;
}
