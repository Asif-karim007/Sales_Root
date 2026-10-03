import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Explains a failed save: a plan limit opens the upgrade sheet, anything
/// else shows the server's message.
void showSalesFailure(BuildContext context, Object error) {
  if (error is ApiFailure && error.isQuota) {
    showSrSheet<void>(
      context: context,
      builder: (sheet) => SrSheet(
        child: SrPlanLocked(
          message: error.message,
          onAction: () {
            Navigator.of(sheet).pop();
            context.push(
              '${Routes.planChoose}?reason=quota&kind=${(error.quota ?? QuotaKind.records).name}',
            );
          },
        ),
      ),
    );
    return;
  }
  final l10n = context.l10n;
  final message = switch (error) {
    ApiFailure(isOffline: true) => l10n.errorOffline,
    ApiFailure(isForbidden: true) => l10n.errorForbidden,
    ApiFailure(:final message) when message.trim().isNotEmpty => message,
    _ => l10n.errorGeneric,
  };
  showSrError(context, message);
}

/// The upgrade route for a plan limit hit while loading [error].
VoidCallback upgradeFor(BuildContext context, Object? error) {
  final kind = error is ApiFailure ? error.quota : null;
  return () => context.push(
    '${Routes.planChoose}?reason=quota&kind=${(kind ?? QuotaKind.records).name}',
  );
}
