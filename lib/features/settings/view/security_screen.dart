import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/features/settings/data/settings_repositories.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/change_pin_sheet.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/features/settings/view/widget/sign_out_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #88: PIN, biometrics and the devices signed in to the account.
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
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(devicesProvider.future),
        child: ListView(
          padding: screenPadding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const _UnlockGroup(),
            const SizedBox(height: 18),
            const _DevicesSection(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(rows: [for (final d in devices) _DeviceRow(device: d)]),
        if (devices.length > 1) ...[
          const SizedBox(height: 10),
          SrButton(
            label: l10n.settingsDevicesSignOutAll,
            variant: SrButtonVariant.secondary,
            icon: Icons.phonelink_erase_rounded,
            expand: true,
            onPressed: () => _signOutAll(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _signOutAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showSrConfirm(
      context,
      title: l10n.settingsDevicesSignOutAll,
      message: l10n.settingsDevicesSignOutAllBody,
      confirmLabel: l10n.settingsDevicesSignOutAllConfirm,
      icon: Icons.phonelink_erase_rounded,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final session = ref.read(sessionProvider.notifier);
    try {
      await showSrLoader(
        context,
        ref.read(settingsRepositoryProvider).signOutEverywhere(),
      );
      await session.signOut();
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failure.message);
    }
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});

  final DeviceSession device;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastActive = device.lastActiveAt;
    return SrListRow(
      title: device.name.isEmpty ? l10n.settingsDeviceUnknown : device.name,
      subtitle: [
        if (device.appVersion case final version?) context.fmt.digits(version),
        if (lastActive != null) context.fmt.dayTime(lastActive),
      ].join(' · '),
      leading: RowIcon(switch (device.kind) {
        DeviceKind.android => Icons.phone_android_rounded,
        DeviceKind.ios => Icons.phone_iphone_rounded,
        DeviceKind.web => Icons.laptop_chromebook_rounded,
      }),
    );
  }
}
