import 'package:flutter/widgets.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/translations/translations.dart';
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

/// Ticks a task off through [complete]. The API cannot reopen a task, so
/// there is no undo.
Future<void> completeTask(
  BuildContext context, {
  required Future<Task> Function() complete,
}) async {
  try {
    await complete();
  } on ApiFailure catch (failure) {
    if (context.mounted) showSrError(context, failureText(context, failure));
    return;
  }
  if (context.mounted) showSrSuccess(context, context.l10n.tasksMarkedDone);
}
