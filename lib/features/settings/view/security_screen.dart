import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/change_pin_sheet.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/features/settings/view/widget/sign_out_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #88: PIN, biometrics, signed-in devices and sign-in history.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsSecurityTitle,
        actions: const [LanguageAction()],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300) {
            ref.read(loginHistoryProvider.notifier).loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(devicesProvider)
              ..invalidate(loginHistoryProvider);
            await ref.read(devicesProvider.future);
          },
          child: ListView(
            padding: screenPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _UnlockGroup(),
              const SizedBox(height: 18),
              const _DevicesSection(),
              const SizedBox(height: 18),
              SrSectionHeader(title: l10n.settingsLoginHistory),
              const SizedBox(height: 8),
              const _LoginHistory(),
              const SizedBox(height: 18),
              SrButton(
                label: l10n.settingsSignOut,
                icon: Icons.logout_rounded,
                variant: SrButtonVariant.danger,
                expand: true,
                onPressed: () => showSrSheet<void>(
                  context: context,
                  builder: (_) => const SignOutSheet(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockGroup extends ConsumerWidget {
  const _UnlockGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(devicePrefsProvider);
    final changedAt = prefs.pinChangedAt;
    return SrRowGroup(
      rows: [
        SrListRow(
          title: l10n.settingsPinChange,
          subtitle: changedAt == null
              ? l10n.settingsPinHint
              : l10n.settingsPinChangedAt(context.fmt.relative(changedAt)),
          leading: const RowIcon(Icons.pin_outlined),
          chevron: true,
          onTap: () async {
            final changed = await showSrSheet<bool>(
              context: context,
              builder: (_) => const ChangePinSheet(),
            );
            if (changed != true || !context.mounted) return;
            showSrSuccess(context, l10n.settingsPinSaved);
          },
        ),
        ToggleRow(
          title: l10n.settingsBiometric,
          subtitle: l10n.settingsBiometricHint,
          leading: const RowIcon(Icons.fingerprint_rounded),
          value: prefs.biometric,
          onChanged: ref.read(devicePrefsProvider.notifier).setBiometric,
        ),
      ],
    );
  }
}

class _DevicesSection extends ConsumerWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(devicesProvider);
    final count = devices.value?.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(
          title: count == null
              ? l10n.settingsDevices
              : l10n.settingsDevicesCount(context.fmt.number(count)),
        ),
        const SizedBox(height: 8),
        AsyncSection(
          value: devices,
          onRetry: () => ref.invalidate(devicesProvider),
          data: (context, list) => _DeviceList(devices: list),
        ),
      ],
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<DeviceSession> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final others = devices.where((d) => !d.isCurrent).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(rows: [for (final d in devices) _DeviceRow(device: d)]),
        if (others > 0) ...[
          const SizedBox(height: 10),
          SrButton(
            label: l10n.settingsDevicesSignOutOthers,
            variant: SrButtonVariant.secondary,
            icon: Icons.phonelink_erase_rounded,
            expand: true,
            onPressed: () => _signOutOthers(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _signOutOthers(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showSrConfirm(
      context,
      title: l10n.settingsDevicesSignOutOthers,
      message: l10n.settingsDevicesSignOutOthersBody,
      confirmLabel: l10n.settingsDevicesSignOutOthersConfirm,
      icon: Icons.phonelink_erase_rounded,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await showSrLoader(
        context,
        ref.read(devicesProvider.notifier).signOutOthers(),
      );
      if (!context.mounted) return;
      showSrSuccess(context, l10n.settingsDevicesSignedOut);
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failure.message);
    }
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device});

  final DeviceSession device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lastActive = device.lastActiveAt;
    final when = device.isCurrent
        ? l10n.settingsDeviceNow
        : lastActive == null
        ? null
        : context.fmt.dayTime(lastActive);
    return SrListRow(
      title: device.name,
      subtitle: [device.location, ?when].join(' · '),
      leading: RowIcon(switch (device.kind) {
        DeviceKind.android => Icons.phone_android_rounded,
        DeviceKind.ios => Icons.phone_iphone_rounded,
        DeviceKind.web => Icons.laptop_chromebook_rounded,
      }, tone: device.isCurrent ? SrAvatarTone.accent : SrAvatarTone.neutral),
      trailing: device.isCurrent
          ? SrTag(l10n.settingsDeviceThis, tone: SrTone.ok)
          : SrButton(
              label: l10n.settingsDeviceRemove,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.secondary,
              onPressed: () => _remove(context, ref),
            ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showSrConfirm(
      context,
      title: l10n.settingsDeviceRemoveTitle(device.name),
      message: l10n.settingsDeviceRemoveBody,
      confirmLabel: l10n.settingsDeviceRemove,
      icon: Icons.phonelink_erase_rounded,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(devicesProvider.notifier).remove(device.id);
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failure.message);
    }
  }
}

class _LoginHistory extends ConsumerWidget {
  const _LoginHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncSection(
      value: ref.watch(loginHistoryProvider),
      onRetry: () => ref.invalidate(loginHistoryProvider),
      skeletonRows: 4,
      data: (context, page) => _LoginList(page: page),
    );
  }
}

class _LoginList extends ConsumerWidget {
  const _LoginList({required this.page});

  final Paged<LoginEvent> page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final failure = page.loadMoreError;
    if (page.isEmpty) {
      return SrCard(child: SrEmptyState(title: l10n.settingsLoginEmpty));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(rows: [for (final e in page.items) _LoginRow(event: e)]),
        if (page.isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SrSkeletonRow(),
          ),
        if (failure != null) ...[
          const SizedBox(height: 10),
          SrErrorState(
            error: failure,
            compact: true,
            onRetry: () => ref.read(loginHistoryProvider.notifier).loadMore(),
          ),
        ],
      ],
    );
  }
}

class _LoginRow extends StatelessWidget {
  const _LoginRow({required this.event});

  final LoginEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = event.at;
    return SrListRow(
      title: at == null
          ? event.device
          : l10n.settingsLoginAt(context.fmt.dayTime(at), event.device),
      subtitle: switch (event.method) {
        LoginMethod.pin => l10n.settingsLoginPin,
        LoginMethod.face => l10n.settingsLoginFace,
        LoginMethod.fingerprint => l10n.settingsLoginFingerprint,
        LoginMethod.otp => l10n.settingsLoginOtp,
        LoginMethod.passwordOtp => l10n.settingsLoginPasswordOtp,
      },
      leading: const RowIcon(Icons.login_rounded),
    );
  }
}
