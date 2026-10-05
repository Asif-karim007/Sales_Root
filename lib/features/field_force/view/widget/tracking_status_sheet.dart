import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/view/widget/ff_info_line.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// "live tracking on", "stopped"… for the duty card.
String trackingLabel(AppLocalizations l10n, TrackerStatus? status) {
  if (status == null) return l10n.ffTrackingLabelOff;
  if (status.stoppedAt != null && !status.isActive) {
    return l10n.ffTrackingLabelStopped;
  }
  return switch (status.state) {
    TrackerState.hidden => l10n.ffTrackingLabelOff,
    TrackerState.available => l10n.ffTrackingLabelNotSetUp,
    TrackerState.consented => l10n.ffTrackingLabelAttention,
    TrackerState.ready => l10n.ffTrackingLabelReady,
    TrackerState.active => l10n.ffTrackingLabelOn,
  };
}

Future<void> showTrackingStatusSheet(BuildContext context) => showSrSheet<void>(
  context: context,
  builder: (_) => const _TrackingStatusSheet(),
);

class _TrackingStatusSheet extends ConsumerWidget {
  const _TrackingStatusSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(trackerProvider);
    return SrSheet(
      title: l10n.ffTrackingSheetTitle,
      child: switch (status) {
        AsyncData(:final value) => _Body(status: value),
        AsyncError(:final error) => SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(trackerProvider),
        ),
        _ => const SrSkeletonList(
          count: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
        ),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.status});

  final TrackerStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final tracker = ref.read(trackerProvider.notifier);
    final lastUpload = status.lastUploadAt;

    void go(String route) {
      Navigator.of(context).pop();
      context.push(route);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrNote(
          message: _message(l10n, fmt),
          tone: status.isActive
              ? SrNoteTone.tint
              : status.state == TrackerState.consented ||
                    status.stoppedAt != null
              ? SrNoteTone.err
              : SrNoteTone.gold,
        ),
        const SizedBox(height: 8),
        FfInfoLine(
          label: l10n.ffTrackingLastSent,
          value: lastUpload == null ? '—' : fmt.relative(lastUpload),
        ),
        FfInfoLine(
          label: l10n.ffTrackingWaiting,
          value: fmt.number(status.buffered),
          last: true,
        ),
        const SizedBox(height: 14),
        if (status.state == TrackerState.available)
          SrButton(
            label: l10n.ffTrackingSetUp,
            expand: true,
            onPressed: () => go(Routes.trackingConsent),
          ),
        if (status.state == TrackerState.consented)
          SrButton(
            label: l10n.ffTrackingFix,
            expand: true,
            onPressed: () => go(Routes.trackingHelp),
          ),
        if (status.state == TrackerState.ready)
          SrButton(
            label: l10n.ffTrackingStart,
            icon: Icons.play_arrow_rounded,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              tracker.start();
            },
          ),
        const SizedBox(height: 8),
        SrButton(
          label: l10n.ffTrackingHelp,
          variant: SrButtonVariant.ghost,
          expand: true,
          onPressed: () => go(Routes.trackingHelp),
        ),
      ],
    );
  }

  String _message(AppLocalizations l10n, AppFormat fmt) {
    final stoppedAt = status.stoppedAt;
    if (status.isActive) {
      return status.insideWindow
          ? l10n.ffTrackingOnBody
          : l10n.ffTrackingOutsideWindow;
    }
    if (stoppedAt != null) return l10n.ffTrackingStoppedAt(fmt.time(stoppedAt));
    return switch (status.state) {
      TrackerState.hidden => l10n.ffTrackingOffBody,
      TrackerState.available => l10n.ffTrackingNotSetUpBody,
      TrackerState.consented => l10n.ffTrackingAttentionBody,
      TrackerState.ready || TrackerState.active => l10n.ffTrackingReadyBody,
    };
  }
}
