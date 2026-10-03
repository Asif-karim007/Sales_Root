import 'package:flutter/widgets.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The line a snackbar shows for [error].
String failureText(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! ApiFailure) return l10n.errorGeneric;
  if (error.isOffline) return l10n.errorOffline;
  if (error.isForbidden) return l10n.errorForbidden;
  if (error.isNotFound) return l10n.errorNotFound;
  return error.message.trim().isEmpty ? l10n.errorGeneric : error.message;
}

/// Ticks [task] off or back on through [change], then offers to undo it.
Future<void> toggleTaskDone(
  BuildContext context, {
  required Task task,
  required Future<Task> Function(bool done) change,
}) async {
  final l10n = context.l10n;
  final done = !task.isDone;
  try {
    await change(done);
  } on ApiFailure catch (failure) {
    if (context.mounted) showSrError(context, failureText(context, failure));
    return;
  }
  if (!context.mounted) return;
  showSrSnack(
    context,
    done ? l10n.tasksMarkedDone : l10n.tasksReopened,
    tone: SrSnackTone.success,
    duration: const Duration(seconds: 4),
    action: SrSnackAction(
      label: l10n.tasksUndo,
      onPressed: () async {
        try {
          await change(!done);
        } on ApiFailure catch (failure) {
          if (context.mounted) {
            showSrError(context, failureText(context, failure));
          }
        }
      },
    ),
  );
}
