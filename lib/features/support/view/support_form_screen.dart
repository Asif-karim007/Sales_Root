import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/providers/ticket_providers.dart';
import 'package:salesroot/features/support/view/widget/attachment_picker.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/features/support/view/widget/support_rows.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #110 a support request: kind, description, screenshots, the diagnostics
/// the user agrees to send, and how to reply.
class SupportFormScreen extends ConsumerStatefulWidget {
  const SupportFormScreen({super.key, this.category, this.from});

  final TicketCategory? category;

  /// The screen or article the user came from.
  final String? from;

  @override
  ConsumerState<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends ConsumerState<SupportFormScreen> {
  final _description = TextEditingController();
  late TicketCategory _category = widget.category ?? TicketCategory.question;
  ReplyChannel _channel = ReplyChannel.inAppSms;
  final List<SupportAttachment> _attachments = [];
  bool _sendScreen = true;
  bool _sendDevice = true;
  bool _sendWorkspace = true;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _attach(AttachmentKind kind) async {
    try {
      final picked = await pickSupportAttachment(kind);
      if (!mounted || picked == null) return;
      setState(() => _attachments.add(picked));
    } on PlatformException {
      if (!mounted) return;
      showSrError(context, context.l10n.supportPickFailed);
    }
  }

  Future<void> _pickChannel() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<ReplyChannel>(
      context: context,
      builder: (_) => SrOptionSheet<ReplyChannel>(
        title: l10n.supportFormReplyHow,
        options: ReplyChannel.values,
        labelOf: l10n.replyChannel,
        isSelected: (channel) => channel == _channel,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _channel = picked);
  }

  void _send() {
    final diagnostics = ref.read(supportDiagnosticsProvider).value;
    final workspace = ref.read(currentWorkspaceProvider);
    final from = widget.from;
    ref
        .read(newTicketProvider.notifier)
        .submit(
          TicketInput(
            category: _category,
            description: _description.text,
            channel: _channel,
            attachments: _attachments,
            diagnostics: {
              if (_sendScreen && from != null) 'Screen': from,
              if (_sendDevice && diagnostics != null) ...{
                'AppVersion': diagnostics.appVersion,
                'Device': diagnostics.device,
                'System': diagnostics.system,
              },
              if (_sendWorkspace && workspace != null)
                'Workspace': workspace.name,
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submit = ref.watch(newTicketProvider);
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    ref.listen(newTicketProvider, (_, next) {
      final ticket = next.value;
      if (ticket != null) {
        showSrSuccess(context, l10n.supportFormSent);
        context.pushReplacement(Routes.supportTicketFor(ticket.id));
      } else if (next.hasError &&
          supportFieldError(next.error, 'Description') == null) {
        showSrError(context, supportFailureText(context, next.error));
      }
    });

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.supportFormTitle,
          actions: const [SupportLanguagePill()],
        ),
        footer: SrButton(
          label: l10n.commonSend,
          expand: true,
          loading: submit.isLoading,
          onPressed: _description.text.trim().isEmpty ? null : _send,
        ),
        body: ListView(
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            SrFieldLabel(l10n.supportFormKind),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final category in TicketCategory.values)
                  SrChip(
                    label: l10n.ticketCategory(category),
                    selected: category == _category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SrTextField(
              controller: _description,
              label: l10n.supportFormDescribe,
              hint: l10n.supportFormDescribeHint,
              error: supportFieldError(submit.error, 'Description'),
              multiline: true,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            _AttachButtons(easy: easy, onAttach: _attach),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final attachment in _attachments)
                    SupportAttachmentChip(
                      name: attachment.name,
                      icon: attachment.kind == AttachmentKind.video
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                      removeLabel: l10n.supportRemoveAttachment,
                      onRemove: () =>
                          setState(() => _attachments.remove(attachment)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _ConsentCard(
              from: widget.from,
              sendScreen: _sendScreen,
              sendDevice: _sendDevice,
              sendWorkspace: _sendWorkspace,
              onScreen: (v) => setState(() => _sendScreen = v),
              onDevice: (v) => setState(() => _sendDevice = v),
              onWorkspace: (v) => setState(() => _sendWorkspace = v),
            ),
            const SizedBox(height: 16),
            SrDropdownField(
              label: l10n.supportFormReplyHow,
              value: l10n.replyChannel(_channel),
              onTap: _pickChannel,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachButtons extends StatelessWidget {
  const _AttachButtons({required this.easy, required this.onAttach});

  final bool easy;
  final ValueChanged<AttachmentKind> onAttach;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenshot = SrButton(
      label: l10n.supportFormScreenshot,
      icon: Icons.image_outlined,
      variant: SrButtonVariant.secondary,
      size: SrButtonSize.sm,
      expand: true,
      onPressed: () => onAttach(AttachmentKind.image),
    );
    if (easy) return screenshot;
    return Row(
      children: [
        Expanded(child: screenshot),
        const SizedBox(width: 10),
        Expanded(
          child: SrButton(
            label: l10n.supportFormRecording,
            icon: Icons.videocam_outlined,
            variant: SrButtonVariant.secondary,
            size: SrButtonSize.sm,
            expand: true,
            onPressed: () => onAttach(AttachmentKind.video),
          ),
        ),
      ],
    );
  }
}

class _ConsentCard extends ConsumerWidget {
  const _ConsentCard({
    required this.from,
    required this.sendScreen,
    required this.sendDevice,
    required this.sendWorkspace,
    required this.onScreen,
    required this.onDevice,
    required this.onWorkspace,
  });

  final String? from;
  final bool sendScreen;
  final bool sendDevice;
  final bool sendWorkspace;
  final ValueChanged<bool> onScreen;
  final ValueChanged<bool> onDevice;
  final ValueChanged<bool> onWorkspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final diagnostics = ref.watch(supportDiagnosticsProvider).value;
    final workspace = ref.watch(currentWorkspaceProvider);
    final from = this.from;

    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.supportFormConsent, style: AppText.label(c.ink2)),
          const SizedBox(height: 4),
          if (from != null)
            _ConsentLine(
              text: l10n.supportFormScreenWas(from),
              value: sendScreen,
              onChanged: onScreen,
            ),
          _ConsentLine(
            text: diagnostics == null
                ? l10n.supportFormDeviceLoading
                : l10n.supportFormDevice(
                    diagnostics.appVersion,
                    diagnostics.device,
                    diagnostics.system,
                  ),
            value: sendDevice,
            onChanged: onDevice,
          ),
          if (workspace != null)
            _ConsentLine(
              text: l10n.supportFormWorkspace(workspace.name),
              value: sendWorkspace,
              onChanged: onWorkspace,
            ),
        ],
      ),
    );
  }
}

class _ConsentLine extends StatelessWidget {
  const _ConsentLine({
    required this.text,
    required this.value,
    required this.onChanged,
  });

  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Row(
      children: [
        Expanded(child: Text(text, style: AppText.lead(c.ink))),
        SrCheckbox(value: value, onChanged: onChanged),
      ],
    );
  }
}
