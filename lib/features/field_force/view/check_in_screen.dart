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
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_info_line.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_map.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/features/field_force/view/widget/minute_builder.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The check-in screen for [companyId], from a route stop or a lead.
String checkInRoute({
  required String companyId,
  String? leadId,
  String? routeStopId,
}) => Uri(
  path: Routes.visitCheckInFor(companyId),
  queryParameters: {'lead': ?leadId, 'stop': ?routeStopId},
).toString();

/// #122 checkin: where the phone is against where the customer is. Far from
/// the customer the visit still starts, and the server flags it.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({
    super.key,
    required this.companyId,
    this.leadId,
    this.routeStopId,
  });

  final String companyId;
  final String? leadId;
  final String? routeStopId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _submitting = false;

  CheckInNotifier get _notifier =>
      ref.read(checkInProvider(widget.companyId).notifier);

  Future<void> _checkIn() async {
    setState(() => _submitting = true);
    try {
      final visit = await _notifier.submit(
        leadId: widget.leadId,
        routeStopId: widget.routeStopId,
      );
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
    final checkIn = ref.watch(checkInProvider(widget.companyId));
    final value = checkIn.value;
    final canCheckIn = value != null && value.fix != null && !value.locating;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffCheckInTitle,
        actions: const [FfLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.ffCheckIn,
        icon: Icons.login_rounded,
        expand: true,
        loading: _submitting,
        onPressed: canCheckIn && !_submitting ? _checkIn : null,
      ),
      body: FieldForceGate(
        module: AppModule.visit,
        right: ModuleRight.add,
        child: switch (checkIn) {
          AsyncValue(:final value?) => _CheckInBody(
            state: value,
            onRetry: _notifier.locate,
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(checkInProvider(widget.companyId)),
          ),
          _ => const SrSkeletonList(count: 3, cards: true),
        },
      ),
    );
  }
}

class _CheckInBody extends StatelessWidget {
  const _CheckInBody({required this.state, required this.onRetry});

  final CheckInState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final target = state.target;
    final fix = state.fix;
    final lat = target.latitude;
    final lng = target.longitude;

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
                title: target.companyName,
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
                FfInfoLine(
                  label: l10n.ffTime,
                  value: context.fmt.time(now),
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SrNote(
          message: state.isFar ? l10n.ffFarVisitNote : l10n.ffCheckInNote,
          tone: state.isFar ? SrNoteTone.gold : SrNoteTone.tint,
        ),
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
    final target = state.target;
    final distance = state.distance;
    final subtitle = [?target.address, ?target.area].join(' · ');

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SrAvatar(name: target.companyName, size: 44, square: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.companyName, style: AppText.rowTitle(c.ink)),
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
