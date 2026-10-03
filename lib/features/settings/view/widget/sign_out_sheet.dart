import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Confirms sign-out, warning about changes still waiting on this phone.
class SignOutSheet extends ConsumerWidget {
  const SignOutSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(syncProvider).value?.pendingCount ?? 0;
    return SrConfirmSheet(
      title: l10n.settingsSignOutTitle,
      message: l10n.settingsSignOutBody,
      icon: Icons.logout_rounded,
      tone: pending > 0 ? SrTone.warn : SrTone.accent,
      bullets: [
        if (pending > 0)
          SrSheetBullet(
            icon: Icons.cloud_off_rounded,
            text: l10n.settingsSignOutPending(context.fmt.number(pending)),
          ),
      ],
      primaryLabel: l10n.settingsSignOut,
      destructive: pending > 0,
      onPrimary: () {
        final session = ref.read(sessionProvider.notifier);
        Navigator.of(context).pop();
        session.signOut();
      },
    );
  }
}
