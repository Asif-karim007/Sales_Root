import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/providers/scan_providers.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/scan_empty.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #42 `qrresult`: a QR code that is not a contact card.
class QrResultScreen extends ConsumerWidget {
  const QrResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(scanSessionProvider).value?.result;
    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.tasksQrTitle,
        actions: const [TasksLanguageToggle()],
      ),
      body: result is QrScanResult
          ? _QrResult(result: result)
          : const ScanEmpty(qr: true),
    );
  }
}

class _QrResult extends ConsumerWidget {
  const _QrResult({required this.result});

  final QrScanResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final link = result.link;
    final canNote = ref.watch(moduleAccessProvider(AppModule.task)).canAdd;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        30,
        SrMetrics.gutter,
        24,
      ),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.goldTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_2_rounded, size: 34, color: c.gold),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.tasksQrNotContact,
          textAlign: TextAlign.center,
          style: AppText.sectionTitle(c.ink, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          link == null ? l10n.tasksQrHoldsText : l10n.tasksQrHoldsLink,
          textAlign: TextAlign.center,
          style: AppText.lead(c.ink2),
        ),
        const SizedBox(height: 14),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SelectableText(
            result.payload,
            style: AppText.body(c.ink, size: 13),
          ),
        ),
        const SizedBox(height: 14),
        if (link != null)
          SrButton(
            label: l10n.tasksQrOpen,
            icon: Icons.open_in_new_rounded,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => _open(context, link),
          )
        else
          SrButton(
            label: l10n.tasksQrCopy,
            icon: Icons.copy_rounded,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => _copy(context),
          ),
        if (canNote) ...[
          const SizedBox(height: 10),
          SrButton(
            label: l10n.tasksQrSaveNote,
            icon: Icons.sticky_note_2_outlined,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => _saveNote(context, ref),
          ),
        ],
        const SizedBox(height: 10),
        SrButton(
          label: l10n.tasksQrScanAgain,
          icon: Icons.qr_code_scanner_rounded,
          expand: true,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.pushReplacement(Routes.scan),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Uri link) async {
    final failed = context.l10n.tasksQrOpenFailed;
    final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) showSrError(context, failed);
  }

  Future<void> _copy(BuildContext context) async {
    final copied = context.l10n.tasksQrCopied;
    await Clipboard.setData(ClipboardData(text: result.payload));
    if (context.mounted) showSrSuccess(context, copied);
  }

  Future<void> _saveNote(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final input = TaskInput(
      title: l10n.tasksQrNoteTitle,
      type: TaskType.own,
      dueDate: DateTime(now.year, now.month, now.day, now.hour + 1),
      notes: result.payload,
    );
    try {
      await showSrLoader(
        context,
        ref.read(taskEditorProvider.notifier).create(input),
      );
    } on ApiFailure catch (failure) {
      if (context.mounted) showSrError(context, failureText(context, failure));
      return;
    }
    if (context.mounted) showSrSuccess(context, l10n.tasksQrNoteSaved);
  }
}
