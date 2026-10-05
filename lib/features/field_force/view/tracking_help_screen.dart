import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/service/oem_helper.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/service/tracker_permissions.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #126 trackingstopped: why sharing stopped and how to fix it on this phone.
class TrackingHelpScreen extends ConsumerStatefulWidget {
  const TrackingHelpScreen({super.key});

  @override
  ConsumerState<TrackingHelpScreen> createState() => _TrackingHelpScreenState();
}

class _TrackingHelpScreenState extends ConsumerState<TrackingHelpScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    final l10n = context.l10n;
    final tracker = ref.read(trackerProvider.notifier);
    setState(() => _checking = true);
    await tracker.refresh();
    final status = await ref.read(trackerProvider.future);
    if (status.state == TrackerState.ready && status.stoppedAt != null) {
      await tracker.start();
    }
    if (!mounted) return;
    setState(() => _checking = false);
    final blocked = status.checklist.any((row) => row.isBlocking);
    blocked
        ? showSrWarning(context, l10n.ffHelpStillBlocked)
        : showSrSuccess(context, l10n.ffHelpAllGood);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracker = ref.watch(trackerProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffHelpTitle,
        actions: const [FfLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.ffHelpCheckAgain,
        icon: Icons.refresh_rounded,
        expand: true,
        loading: _checking,
        onPressed: _checking ? null : _checkAgain,
      ),
      body: switch (tracker) {
        AsyncValue(:final value?) => _HelpBody(status: value),
        AsyncError(:final error) => SrErrorState(
          error: error,
          onRetry: () => ref.invalidate(trackerProvider),
        ),
        _ => const SrSkeletonList(count: 4),
      },
    );
  }
}

class _HelpBody extends ConsumerWidget {
  const _HelpBody({required this.status});

  final TrackerStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final stoppedAt = status.stoppedAt;
    final rows = [
      for (final row in status.checklist)
        if (row.level != PermissionLevel.notApplicable) row,
    ];

    final (message, tone) = stoppedAt != null && !status.isActive
        ? (l10n.ffHelpStopped(fmt.time(stoppedAt)), SrNoteTone.err)
        : status.isActive
        ? (l10n.ffHelpSharing, SrNoteTone.tint)
        : status.state == TrackerState.available
        ? (l10n.ffTrackingNotSetUpBody, SrNoteTone.gold)
        : (l10n.ffHelpNotSharing, SrNoteTone.gold);

    return ListView(
      physics: const SrScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        SrNote(
          message: message,
          tone: tone,
          action: status.state == TrackerState.available
              ? SrButton(
                  label: l10n.ffTrackingSetUp,
                  size: SrButtonSize.sm,
                  onPressed: () => context.push(Routes.trackingConsent),
                )
              : null,
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          SrRowGroup(
            title: l10n.ffHelpToFix,
            rows: [for (final row in rows) _FixRow(row: row)],
          ),
        ],
        const SizedBox(height: 12),
        const _PhoneTips(),
      ],
    );
  }
}

class _FixRow extends ConsumerWidget {
  const _FixRow({required this.row});

  final TrackerPermissionRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (icon, title, detail) = switch (row.step) {
      TrackerPermissionStep.location => (
        Icons.location_on_outlined,
        l10n.ffFixLocation,
        switch (row.location) {
          LocationGrant.always => l10n.ffFixLocationAlways,
          LocationGrant.whileUsing => l10n.ffFixLocationWhileUsing,
          _ => l10n.ffFixLocationDenied,
        },
      ),
      TrackerPermissionStep.gps => (
        Icons.gps_fixed_rounded,
        l10n.ffFixGps,
        row.isGreen ? l10n.ffFixGpsOn : l10n.ffFixGpsOff,
      ),
      TrackerPermissionStep.battery => (
        Icons.battery_alert_outlined,
        l10n.ffFixBattery,
        row.isGreen ? l10n.ffFixBatteryOk : l10n.ffFixBatterySaver,
      ),
      TrackerPermissionStep.notifications => (
        Icons.notifications_outlined,
        l10n.ffFixNotifications,
        row.isGreen ? l10n.ffFixNotificationsOn : l10n.ffFixNotificationsOff,
      ),
      TrackerPermissionStep.precise => (
        Icons.my_location_rounded,
        l10n.ffFixPrecise,
        row.isGreen ? l10n.ffFixPreciseOn : l10n.ffFixPreciseOff,
      ),
    };
    final (tone, label, variant) = switch (row.level) {
      PermissionLevel.blocked => (
        SrAvatarTone.danger,
        l10n.ffFix,
        SrButtonVariant.primary,
      ),
      PermissionLevel.pending => (
        SrAvatarTone.gold,
        row.step == TrackerPermissionStep.battery ? l10n.ffTurnOff : l10n.ffFix,
        SrButtonVariant.secondary,
      ),
      PermissionLevel.granted || PermissionLevel.notApplicable => (
        SrAvatarTone.neutral,
        l10n.ffOk,
        SrButtonVariant.secondary,
      ),
    };
    return SrListRow(
      leading: SrAvatar(icon: icon, tone: tone),
      title: title,
      subtitle: detail,
      trailing: SrButton(
        label: label,
        size: SrButtonSize.sm,
        variant: variant,
        onPressed: row.isGreen
            ? null
            : () => ref
                  .read(trackerProvider.notifier)
                  .requestPermission(row.step),
      ),
    );
  }
}

class _PhoneTips extends ConsumerWidget {
  const _PhoneTips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final phone = ref.watch(phoneInfoProvider).value;
    if (phone == null) return const SizedBox.shrink();
    final tip = switch (phone.vendor) {
      PhoneVendor.samsung => l10n.ffTipSamsung,
      PhoneVendor.xiaomi => l10n.ffTipXiaomi,
      PhoneVendor.oppo ||
      PhoneVendor.realme ||
      PhoneVendor.oneplus => l10n.ffTipOppo,
      PhoneVendor.vivo => l10n.ffTipVivo,
      PhoneVendor.transsion => l10n.ffTipTranssion,
      PhoneVendor.huawei => l10n.ffTipHuawei,
      PhoneVendor.iphone => l10n.ffTipIphone,
      PhoneVendor.other => l10n.ffTipOther,
    };
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phone.model.isEmpty
                ? l10n.ffTipsTitleGeneric
                : l10n.ffTipsTitle(phone.model),
            style: AppText.rowTitle(c.ink, size: 14),
          ),
          const SizedBox(height: 6),
          Text(tip, style: AppText.body(c.ink, size: 13)),
          if (phone.vendor.killsBackgroundApps) ...[
            const SizedBox(height: 6),
            Text(l10n.ffTipAutoStart, style: AppText.body(c.ink, size: 13)),
          ],
          const SizedBox(height: 6),
          Text(l10n.ffTipBattery, style: AppText.meta(c.ink2)),
        ],
      ),
    );
  }
}
