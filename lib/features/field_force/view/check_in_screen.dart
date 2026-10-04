import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';
import 'package:salesroot/features/field_force/view/widget/far_check_in_sheet.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_info_line.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_map.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/features/field_force/view/widget/minute_builder.dart';
import 'package:salesroot/features/field_force/view/widget/photo_capture.dart';
import 'package:salesroot/features/field_force/view/widget/visit_note_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #122 checkin: where the phone is against where the customer is, with a
/// photo and a note. Beyond the check-in radius it goes through #123.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, required this.visitId});

  final int visitId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _submitting = false;

  CheckInNotifier get _notifier =>
      ref.read(checkInProvider(widget.visitId).notifier);

  Future<void> _checkIn(CheckInState state) async {
    String? reason;
    if (state.isFar) {
      reason = await showFarCheckInSheet(context, visitId: widget.visitId);
      if (reason == null || !mounted) return;
    }
    setState(() => _submitting = true);
    try {
      final visit = await _notifier.submit(reason: reason);
      if (!mounted) return;
      showSrSuccess(context, context.l10n.ffCheckedInVisit(visit.title));
      context.pushReplacement(Routes.visitFor(visit.id));
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } on LocationFailure {
      if (mounted) showSrError(context, context.l10n.ffLocationUnavailable);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final checkIn = ref.watch(checkInProvider(widget.visitId));
    final value = checkIn.value;
    final visit = value?.visit;
    final canCheckIn =
        value != null &&
        value.fix != null &&
        !value.locating &&
        visit?.status == VisitStatus.planned;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffCheckInTitle,
        actions: const [FfLanguageToggle()],
      ),
      footer: visit != null && visit.status != VisitStatus.planned
          ? SrButton(
              label: l10n.ffOpenVisit,
              expand: true,
              onPressed: () =>
                  context.pushReplacement(Routes.visitFor(visit.id)),
            )
          : SrButton(
              label: l10n.ffCheckIn,
              icon: Icons.login_rounded,
              expand: true,
              loading: _submitting,
              onPressed: canCheckIn && !_submitting
                  ? () => _checkIn(value)
                  : null,
            ),
      body: FieldForceGate(
        module: AppModule.visit,
        right: ModuleRight.add,
        child: switch (checkIn) {
          AsyncValue(:final value?) => _CheckInBody(
            state: value,
            onRetry: _notifier.locate,
            onPhoto: () async {
              final path = await takeVisitPhoto(context);
              if (path != null) _notifier.setPhoto(path);
            },
            onNote: () async {
              final note = await showVisitNoteSheet(
                context,
                initial: value.note,
              );
              if (note != null) _notifier.setNote(note);
            },
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(checkInProvider(widget.visitId)),
          ),
          _ => const SrSkeletonList(count: 3, cards: true),
        },
      ),
    );
  }
}

class _CheckInBody extends StatelessWidget {
  const _CheckInBody({
    required this.state,
    required this.onRetry,
    required this.onPhoto,
    required this.onNote,
  });

  final CheckInState state;
  final VoidCallback onRetry;
  final VoidCallback onPhoto;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visit = state.visit;
    final fix = state.fix;
    final lat = visit.latitude;
    final lng = visit.longitude;
    final photo = state.photoPath;
    final note = state.note;

    return ListView(
      physics: const SrScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        FfMap(
          height: 170,
          pins: [
            if (lat != null && lng != null)
              FfMapPin(
                id: 'customer',
                latitude: lat,
                longitude: lng,
                title: visit.title,
              ),
            if (fix != null)
              FfMapPin(
                id: 'me',
                latitude: fix.latitude,
                longitude: fix.longitude,
                title: l10n.ffYouAreHere,
                tone: FfPinTone.me,
              ),
          ],
          ring: lat == null || lng == null
              ? null
              : FfMapRing(
                  latitude: lat,
                  longitude: lng,
                  radiusMetres: state.radius.toDouble(),
                ),
        ),
        const SizedBox(height: 12),
        _CustomerCard(state: state),
        const SizedBox(height: 12),
        if (state.issue case final issue?) ...[
          _LocationIssueNote(issue: issue, onRetry: onRetry),
          const SizedBox(height: 12),
        ],
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FfClockBuilder(
            builder: (context, now) => Column(
              children: [
                FfInfoLine(label: l10n.ffGps, value: _gpsLine(context)),
                FfInfoLine(label: l10n.ffTime, value: context.fmt.time(now)),
                FfInfoLine(
                  label: l10n.ffPurpose,
                  value: visit.purpose ?? '—',
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SrButton(
                label: photo == null ? l10n.ffPhoto : l10n.ffRetakePhoto,
                icon: Icons.photo_camera_outlined,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: onPhoto,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrButton(
                label: note == null ? l10n.ffNote : l10n.ffEditNote,
                icon: Icons.edit_note_rounded,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: onNote,
              ),
            ),
          ],
        ),
        if (photo != null || note != null) ...[
          const SizedBox(height: 12),
          _Attachments(photo: photo, note: note),
        ],
        const SizedBox(height: 12),
        SrNote(message: l10n.ffCheckInNote),
      ],
    );
  }

  String _gpsLine(BuildContext context) {
    final l10n = context.l10n;
    final fix = state.fix;
    if (state.locating) return l10n.ffGpsSearching;
    if (fix == null) return l10n.ffGpsNoFix;
    final accuracy = context.ffDistance(fix.accuracy);
    return state.isFar ? l10n.ffGpsFar(accuracy) : l10n.ffGpsMatched(accuracy);
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final visit = state.visit;
    final planned = visit.plannedAt;
    final distance = state.distance;
    final subtitle = [
      ?visit.address,
      if (planned != null) l10n.ffPlannedAt(context.fmt.time(planned)),
    ].join(' · ');

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SrAvatar(name: visit.title, size: 44, square: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.title, style: AppText.rowTitle(c.ink)),
                Text(subtitle, style: AppText.meta(c.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state.locating)
            SrTag(l10n.ffLocating, icon: Icons.gps_not_fixed_rounded)
          else if (distance != null)
            SrTag(
              l10n.ffAway(context.ffDistance(distance)),
              tone: state.isFar ? SrTone.warn : SrTone.ok,
            ),
        ],
      ),
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.photo, required this.note});

  final String? photo;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final photo = this.photo;
    final note = this.note;
    return SrCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            FfPhotoThumb(path: photo, size: 56),
            const SizedBox(width: 12),
          ],
          if (note != null)
            Expanded(
              child: Text(
                note,
                style: AppText.body(c.ink, size: 14),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationIssueNote extends StatelessWidget {
  const _LocationIssueNote({required this.issue, required this.onRetry});

  final LocationIssue issue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (message, action, onAction) = switch (issue) {
      LocationIssue.serviceOff => (
        l10n.ffLocationServiceOff,
        l10n.ffTurnOnGps,
        () async {
          await Geolocator.openLocationSettings();
        },
      ),
      LocationIssue.deniedForever => (
        l10n.ffLocationDeniedForever,
        l10n.ffOpenSettings,
        () async {
          await openAppSettings();
        },
      ),
      LocationIssue.denied => (
        l10n.ffLocationDenied,
        l10n.ffAllow,
        () async => onRetry(),
      ),
      LocationIssue.unavailable => (
        l10n.ffLocationUnavailable,
        l10n.ffRetry,
        () async => onRetry(),
      ),
    };
    return SrNote(
      tone: SrNoteTone.err,
      icon: Icons.location_off_outlined,
      message: message,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrButton(
            label: action,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: onAction,
          ),
          const SizedBox(width: 6),
          SrIconButton(
            icon: Icons.refresh_rounded,
            tooltip: l10n.ffRetry,
            compact: true,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
