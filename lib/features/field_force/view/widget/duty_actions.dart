import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Starts the duty day, then live tracking: straight away when it is set up,
/// or through the consent or help screen when it is not.
Future<void> dutyCheckIn(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  try {
    final log = await showSrLoader(
      context,
      ref.read(attendanceTodayProvider.notifier).checkIn(),
    );
    if (!context.mounted) return;
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
        if (tracker.pausedAt == null) {
          await ref.read(trackerProvider.notifier).start();
        }
      case TrackerState.hidden || TrackerState.active:
        break;
    }
  } on ApiFailure catch (failure) {
    if (context.mounted) showSrError(context, failure.message);
  }
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
  try {
    final log = await showSrLoader(
      context,
      ref.read(attendanceTodayProvider.notifier).checkOut(),
    );
    if (!context.mounted) return;
    showSrSuccess(
      context,
      l10n.ffCheckedOutWorked(
        context.ffClockDuration(log.workedUntil(DateTime.now())),
      ),
    );
    await ref.read(trackerProvider.notifier).stop();
  } on ApiFailure catch (failure) {
    if (context.mounted) showSrError(context, failure.message);
  }
}
