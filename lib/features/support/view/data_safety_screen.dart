import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/support_links.dart';
import 'package:salesroot/features/support/view/widget/support_done_sheet.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #113 how the user's data is protected, with a data export.
class DataSafetyScreen extends ConsumerWidget {
  const DataSafetyScreen({super.key});

  Future<void> _privacy(BuildContext context) async {
    final failed = context.l10n.supportCantOpen;
    final opened = await openExternal(Uri.parse(SupportLinks.privacyPolicy));
    if (opened || !context.mounted) return;
    showSrError(context, failed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final export = ref.watch(dataExportProvider);
    ref.listen(dataExportProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        showSrSuccess(context, l10n.supportSafetyExportStarted);
      } else if (next.hasError) {
        showSrError(context, supportFailureText(context, next.error));
      }
    });
    final points = [
      (
        Icons.lock_outline_rounded,
        l10n.supportSafetyEncrypted,
        l10n.supportSafetyEncryptedBody,
      ),
      (
        Icons.person_outline_rounded,
        l10n.supportSafetyPersonal,
        l10n.supportSafetyPersonalBody,
      ),
      (
        Icons.logout_rounded,
        l10n.supportSafetyLeave,
        l10n.supportSafetyLeaveBody,
      ),
      (
        Icons.location_on_outlined,
        l10n.supportSafetyLocation,
        l10n.supportSafetyLocationBody,
      ),
      (
        Icons.backup_outlined,
        l10n.supportSafetyBackups,
        l10n.supportSafetyBackupsBody,
      ),
      (
        Icons.download_outlined,
        l10n.supportSafetyDownload,
        l10n.supportSafetyDownloadBody,
      ),
    ];

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.supportSafetyTitle,
        actions: const [SupportLanguagePill()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SrMetrics.gutter),
        children: [
          const Center(child: SupportBigCheck(icon: Icons.shield_outlined)),
          const SizedBox(height: 10),
          Text(
            l10n.supportSafetyHeadline,
            textAlign: TextAlign.center,
            style: AppText.hero(c.ink, size: 22),
          ),
          const SizedBox(height: 16),
          SrRowGroup(
            rows: [
              for (final (icon, title, body) in points)
                SrListRow(
                  title: title,
                  subtitle: body,
                  leading: SrAvatar(icon: icon, tone: SrAvatarTone.accent),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SrButton(
                  label: export.value == true
                      ? l10n.supportSafetyExportRequested
                      : l10n.supportSafetyExport,
                  icon: Icons.download_rounded,
                  variant: SrButtonVariant.secondary,
                  size: SrButtonSize.sm,
                  expand: true,
                  loading: export.isLoading,
                  onPressed: export.value == true
                      ? null
                      : () => ref.read(dataExportProvider.notifier).request(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrButton(
                  label: l10n.supportSafetyPrivacy,
                  icon: Icons.policy_outlined,
                  variant: SrButtonVariant.secondary,
                  size: SrButtonSize.sm,
                  expand: true,
                  onPressed: () => _privacy(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
