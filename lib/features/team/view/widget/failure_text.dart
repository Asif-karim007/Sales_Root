import 'package:flutter/widgets.dart';

import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The message to show for a failed call, preferring our own wording for
/// offline and permission errors.
String failureText(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! SrDisplayableFailure) return l10n.errorGeneric;
  return switch (error.statusCode) {
    0 => l10n.errorOffline,
    403 => l10n.errorForbidden,
    404 => l10n.errorNotFound,
    402 => l10n.planLockedTitle,
    _ => error.message.isEmpty ? l10n.errorGeneric : error.message,
  };
}
