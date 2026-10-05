import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #125 consent: the member agrees to live tracking while checked in, then
/// the phone asks for location "always".
class TrackingConsentScreen extends ConsumerStatefulWidget {
  const TrackingConsentScreen({super.key});

  @override
  ConsumerState<TrackingConsentScreen> createState() =>
      _TrackingConsentScreenState();
}

class _TrackingConsentScreenState extends ConsumerState<TrackingConsentScreen> {
  bool _saving = false;

  Future<void> _answer({required bool agree}) async {
    final l10n = context.l10n;
    final tracker = ref.read(trackerProvider.notifier);
    setState(() => _saving = true);
    try {
      if (!agree) {
        await tracker.declineConsent();
        if (mounted) context.pop();
        return;
      }
      await tracker.giveConsent();
      final status = await ref.read(trackerProvider.future);
      final checkedIn =
          ref.read(attendanceTodayProvider).value?.log?.isCheckedIn ?? false;
      if (status.state == TrackerState.ready && checkedIn) {
        await tracker.start();
      }
      if (!mounted) return;
      if (status.state == TrackerState.consented) {
        context.pushReplacement(Routes.trackingHelp);
      } else {
        showSrSuccess(context, l10n.ffConsentThanks);
        context.pop();
      }
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(trackingSettingsProvider);
    final consent = ref.watch(trackingConsentProvider).value;
    final enabled = settings.value?.liveTracking ?? true;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffConsentTitle,
        actions: const [FfLanguageToggle()],
      ),
      footer: enabled
          ? Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.ffConsentNotNow,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: _saving ? null : () => _answer(agree: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.ffConsentAgree,
                    expand: true,
                    loading: _saving,
                    onPressed: _saving ? null : () => _answer(agree: true),
                  ),
                ),
              ],
            )
          : null,
      body: switch (settings) {
        AsyncValue(:final value?) when !value.liveTracking => SrEmptyState(
          icon: Icons.location_disabled_outlined,
          title: l10n.ffConsentOffTitle,
          message: l10n.ffConsentOffBody,
        ),
        AsyncValue(:final value?) => _ConsentBody(
          settings: value,
          workspace: consent?.workspaceName ?? l10n.ffYourTeam,
          agreedAt: consent?.at,
        ),
        AsyncError(:final error) => SrErrorState(
          error: error,
          onRetry: () => ref.invalidate(trackingSettingsProvider),
        ),
        _ => const SrSkeletonList(count: 4),
      },
    );
  }
}

class _ConsentBody extends StatelessWidget {
  const _ConsentBody({
    required this.settings,
    required this.workspace,
    required this.agreedAt,
  });

  final TrackingSettings settings;
  final String workspace;
  final DateTime? agreedAt;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final agreedAt = this.agreedAt;
    final points = [
      l10n.ffConsentWhileCheckedIn,
      l10n.ffConsentWhoSees,
      l10n.ffConsentEvery(
        fmt.number(settings.heartbeatMinutes.round().clamp(1, 60)),
      ),
      l10n.ffConsentNeverSold,
    ];

    return ListView(
      physics: const SrScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
            child: Icon(
              Icons.share_location_rounded,
              size: 34,
              color: c.accent,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.ffConsentHeadline,
          textAlign: TextAlign.center,
          style: AppText.hero(c.ink, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.ffConsentLead(workspace),
          textAlign: TextAlign.center,
          style: AppText.lead(c.ink2),
        ),
        const SizedBox(height: 18),
        SrCard(
          tone: SrCardTone.tint,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: c.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: AppText.body(c.ink, size: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrNote(
          message: agreedAt == null
              ? l10n.ffConsentNextStep
              : l10n.ffConsentAgreedOn(fmt.date(agreedAt)),
        ),
      ],
    );
  }
}
