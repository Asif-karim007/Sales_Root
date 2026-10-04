import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The line a snackbar shows for a failed request.
String failureText(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! ApiFailure) return l10n.errorGeneric;
  if (error.isOffline) return l10n.errorOffline;
  if (error.isForbidden) return l10n.errorForbidden;
  if (error.isNotFound) return l10n.errorNotFound;
  final message = error.message.trim();
  return message.isEmpty ? l10n.errorGeneric : message;
}

/// Where the upgrade button of a quota prompt goes.
String upgradeRoute(QuotaKind kind) =>
    '${Routes.planChoose}?reason=quota&kind=${kind.name}';

/// Shows a failed mutation: the upgrade prompt for a plan limit, otherwise
/// an error snackbar.
void showFailure(
  BuildContext context,
  Object error, {
  QuotaKind quota = QuotaKind.records,
}) {
  if (error is ApiFailure && error.isQuota) {
    final kind = error.quota ?? quota;
    showSrSheet<void>(
      context: context,
      builder: (sheetContext) => SrSheet(
        child: SrPlanLocked(
          message: error.message.trim().isEmpty ? null : error.message,
          onAction: () {
            Navigator.of(sheetContext).pop();
            context.push(upgradeRoute(kind));
          },
        ),
      ),
    );
    return;
  }
  showSrError(context, failureText(context, error));
}
