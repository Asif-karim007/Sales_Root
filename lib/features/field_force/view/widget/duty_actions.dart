import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/view/widget/far_check_in_sheet.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/photo_capture.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Starts the duty day, then live tracking: straight away when it is set up,
/// or through the consent or help screen when it is not. A selfie is taken
/// first when the workspace asks for one.
Future<void> dutyCheckIn(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final today = ref.read(attendanceTodayProvider).value;
  String? selfie;
  if (today?.settings.selfieOnCheckIn ?? false) {
    selfie = await takeSelfie(context);
    if (selfie == null || !context.mounted) return;
  }
  final log = await _checkIn(context, ref, selfie: selfie);
  if (log == null || !context.mounted) return;
  final at = log.checkInAt;
  showSrSuccess(
    context,
    at == null ? l10n.ffCheckedIn : l10n.ffCheckedInAt(context.fmt.time(at)),
  );
  final tracker = await ref.read(trackerProvider.future);
  if (!context.mounted) return;
  switch (tracker.state) {
    case TrackerState.available:
      context.push(Routes.trackingConsent);
    case TrackerState.consented:
      context.push(Routes.trackingHelp);
    case TrackerState.ready:
      await ref.read(trackerProvider.notifier).start();
    case TrackerState.hidden || TrackerState.active:
      break;
  }
}

/// Checks in, asking for a reason when the server wants one; null when it
/// did not happen.
Future<AttendanceLog?> _checkIn(
  BuildContext context,
  WidgetRef ref, {
  String? selfie,
  String? reason,
}) async {
  final l10n = context.l10n;
  try {
    return await showSrLoader(
      context,
      ref
          .read(attendanceTodayProvider.notifier)
          .checkIn(selfiePath: selfie, reason: reason),
    );
  } on ApiFailure catch (failure) {
    if (!context.mounted) return null;
    if (failure.isValidation &&
        reason == null &&
        failure.fieldErrors.containsKey('reason')) {
      final given = await showFarCheckInSheet(context);
      if (given == null || !context.mounted) return null;
      return _checkIn(context, ref, selfie: selfie, reason: given);
    }
    showSrError(context, failure.message);
  } on LocationFailure {
    if (context.mounted) showSrError(context, l10n.ffLocationUnavailable);
  }
  return null;
}

/// Ends the duty day after a confirmation, and stops live tracking.
Future<void> dutyCheckOut(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final confirmed = await showSrConfirm(
    context,
    title: l10n.ffCheckOutConfirmTitle,
    message: l10n.ffCheckOutConfirmBody,
    confirmLabel: l10n.ffCheckOut,
    icon: Icons.logout_rounded,
  );
  if (!confirmed || !context.mounted) return;
  final checkIn = ref.read(attendanceTodayProvider).value?.log?.checkInAt;
  try {
    final log = await showSrLoader(
      context,
      ref.read(attendanceTodayProvider.notifier).checkOut(),
    );
    if (!context.mounted) return;
    final out = log.checkOutAt;
    showSrSuccess(
      context,
      checkIn == null || out == null
          ? l10n.ffCheckedOutAt(context.fmt.time(out ?? DateTime.now()))
          : l10n.ffCheckedOutWorked(
              context.ffClockDuration(out.difference(checkIn).inMinutes),
            ),
    );
    await ref.read(trackerProvider.notifier).stop();
  } on ApiFailure catch (failure) {
    if (context.mounted) showSrError(context, failure.message);
  }
}
