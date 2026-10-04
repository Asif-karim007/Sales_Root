import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Explains why a save failed: a plan limit opens the upgrade sheet, anything
/// else is an error snackbar.
void showHrFailure(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is ApiFailure && error.isQuota) {
    showSrSheet<void>(
      context: context,
      builder: (sheet) => SrSheet(
        child: SrPlanLocked(
          message: error.message,
          onAction: () {
            Navigator.of(sheet).pop();
            context.push(
              '${Routes.planChoose}?reason=quota&kind=${(error.quota ?? QuotaKind.storage).name}',
            );
          },
        ),
      ),
    );
    return;
  }
  final message = switch (error) {
    ApiFailure(isOffline: true) => l10n.errorOffline,
    ApiFailure(isForbidden: true) => l10n.errorForbidden,
    ApiFailure(:final message) when message.isNotEmpty => message,
    _ => l10n.errorGeneric,
  };
  showSrError(context, message);
}

/// The plans screen for a 402 from a list or detail.
void openHrUpgrade(
  BuildContext context, [
  QuotaKind kind = QuotaKind.storage,
]) => context.push('${Routes.planChoose}?reason=quota&kind=${kind.name}');

/// Leaves a form after saving: back where it was opened from, or to
/// [fallback] when it was opened by a link.
void closeHrForm(BuildContext context, String fallback) =>
    context.canPop() ? context.pop() : context.go(fallback);
