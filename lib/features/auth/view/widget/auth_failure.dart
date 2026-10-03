import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/l10n/l10n.dart';

/// A snackbar line for a failed auth request that has no field to point at.
String authFailureText(AppLocalizations l10n, Object error) => switch (error) {
  ApiFailure(isOffline: true) => l10n.errorOffline,
  ApiFailure(isUnauthorised: true) => l10n.errorSessionExpired,
  ApiFailure(isForbidden: true) => l10n.errorForbidden,
  ApiFailure(isNotFound: true) => l10n.errorNotFound,
  _ => l10n.errorGeneric,
};

/// The server's message for [field], when the failure is a 400 or 409
/// naming it.
String? authFieldError(Object? error, String field) =>
    error is ApiFailure && (error.isValidation || error.isConflict)
    ? error.fieldError(field)
    : null;
