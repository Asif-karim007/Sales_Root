import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The text for a failed lead request: our own words for the common cases,
/// the server's otherwise.
String leadFailureText(AppLocalizations l10n, Object error) {
  if (error is! ApiFailure) return l10n.errorGeneric;
  if (error.isOffline) return l10n.errorOffline;
  if (error.isForbidden) return l10n.errorForbidden;
  if (error.isNotFound) return l10n.errorNotFound;
  if (error.isQuota) return l10n.planLockedBody;
  return error.message.isEmpty ? l10n.errorGeneric : error.message;
}

/// Shows the snackbars for lead actions started on [surface]: a move with
/// a ten-second undo, task done, delete and failures. Call from `build`.
void listenLeadEvents(
  BuildContext context,
  WidgetRef ref,
  LeadSurface surface, {
  VoidCallback? onDeleted,
}) {
  ref.listen(leadActionsProvider, (_, event) {
    if (event == null || event.origin != surface) return;
    final l10n = context.l10n;
    switch (event) {
      case LeadMoved(:final move, :final stage):
        final actions = ref.read(leadActionsProvider.notifier);
        showSrSnack(
          context,
          stage.isWon
              ? l10n.leadsMarkedWon
              : l10n.leadsMovedTo(stage.name.of(context.fmt.isBangla)),
          tone: SrSnackTone.success,
          duration: const Duration(seconds: 10),
          action: SrSnackAction(
            label: l10n.leadsUndo,
            onPressed: () => actions.undoMove(move, surface),
          ),
        );
      case LeadMoveUndone():
        showSrInfo(context, l10n.leadsMoveUndone);
      case LeadTaskDone():
        showSrSuccess(context, l10n.leadsTaskDone);
      case LeadDeleted():
        showSrSuccess(context, l10n.leadsDeleted);
        onDeleted?.call();
      case LeadActionFailed(:final failure):
        showSrError(context, leadFailureText(l10n, failure));
    }
  });
}
