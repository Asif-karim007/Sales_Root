import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/view/widget/audience_field.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/merge_tags.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #145 Write a bulk email to a segment, with an attachment and an order
/// button.
class BulkEmailScreen extends ConsumerStatefulWidget {
  const BulkEmailScreen({super.key});

  @override
  ConsumerState<BulkEmailScreen> createState() => _BulkEmailScreenState();
}

class _BulkEmailScreenState extends ConsumerState<BulkEmailScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  AudienceSegment _segment = AudienceSegment.dealers;
  String? _attachment;
  bool _orderButton = true;
  bool _tracking = true;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final submit = ref.watch(emailCampaignSubmitProvider);
    ref.listen(emailCampaignSubmitProvider, _onSubmit);
    final audiences = ref.watch(campaignAudiencesProvider);
    final balance = ref.watch(messagingBalanceProvider).value;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final reach =
        audiences.value
            ?.where((a) => a.segment == _segment)
            .firstOrNull
            ?.count ??
        0;
    final failure = switch (submit) {
      AsyncError(:final ApiFailure error) => error,
      _ => null,
    };
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthCampaignsBulkEmail,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: audiences,
        onRetry: () => ref.invalidate(campaignAudiencesProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 5, cards: true),
        data: (context, list) => SrKeyboardDismiss(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              AudienceField(
                audiences: list,
                segment: _segment,
                reach: reach,
                onChanged: (segment) => setState(() => _segment = segment),
              ),
              const SizedBox(height: 12),
              SrTextField(
                controller: _subject,
                label: l10n.growthEmailSubject,
                hint: l10n.growthEmailSubjectHint,
                error: failure?.fieldError('Subject') == null
                    ? null
                    : l10n.commonRequired,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SrTextField(
                controller: _body,
                label: l10n.growthEmailBody,
                hint: l10n.growthEmailBodyHint,
                multiline: true,
                error: failure?.fieldError('Body') == null
                    ? null
                    : l10n.commonRequired,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              MergeTags(
                tags: const ['{{name}}', '{{company}}'],
                controller: _body,
                onInserted: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _AttachmentRow(
                name: _attachment,
                onPick: _pickFile,
                onRemove: () => setState(() => _attachment = null),
              ),
              const SizedBox(height: 12),
              _EmailPreview(
                from: balance?.fromEmail ?? '',
                subject: _subject.text,
                body: _body.text,
                attachment: _attachment,
                orderButton: _orderButton,
              ),
              const SizedBox(height: 12),
              SrCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    GrowthToggleRow(
                      title: l10n.growthEmailOrderButton,
                      value: _orderButton,
                      onChanged: (v) => setState(() => _orderButton = v),
                    ),
                    if (!easy)
                      GrowthToggleRow(
                        title: l10n.growthEmailTracking,
                        subtitle: l10n.growthEmailTrackingHint,
                        value: _tracking,
                        onChanged: (v) => setState(() => _tracking = v),
                      ),
                  ],
                ),
              ),
              if (balance != null) ...[
                const SizedBox(height: 12),
                GrowthInfoCard(
                  lines: [
                    (l10n.growthEmailFrom, balance.fromEmail),
                    (
                      l10n.growthEmailLimit,
                      l10n.growthCampaignOf(
                        fmt.number(balance.emailUsed + reach),
                        fmt.number(balance.emailLimit),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: SrButton(
              label: l10n.growthEmailPreview,
              variant: SrButtonVariant.secondary,
              onPressed: () => _preview(balance?.fromEmail ?? ''),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SrButton(
              label: l10n.growthSmsSendTo(fmt.number(reach)),
              loading: submit.isLoading,
              onPressed: reach == 0 ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    ref
        .read(emailCampaignSubmitProvider.notifier)
        .submit(
          EmailCampaignInput(
            segment: _segment,
            subject: _subject.text,
            body: _body.text,
            trackOpens: _tracking,
            attachmentName: _attachment,
            buttonLabel: _orderButton
                ? context.l10n.growthEmailPlaceOrder
                : null,
          ),
        );
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) return;
    setState(() => _attachment = file.name);
  }

  void _preview(String from) => showSrSheet<void>(
    context: context,
    builder: (context) => SrSheet(
      title: context.l10n.growthEmailPreview,
      child: SingleChildScrollView(
        child: _EmailPreview(
          from: from,
          subject: _subject.text,
          body: _body.text,
          attachment: _attachment,
          orderButton: _orderButton,
          sample: true,
        ),
      ),
    ),
  );

  void _onSubmit(AsyncValue<Campaign?>? _, AsyncValue<Campaign?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncError(:final ApiFailure error) when error.isValidation:
        if (error.fieldErrors.isEmpty) {
          showSrError(context, growthFailureText(context, error));
        }
      case AsyncError(:final error):
        showSrError(context, growthFailureText(context, error));
      case AsyncData(:final value?):
        showSrSuccess(
          context,
          l10n.growthEmailSent(context.fmt.number(value.recipients)),
        );
        context.pop();
      default:
        return;
    }
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.name,
    required this.onPick,
    required this.onRemove,
  });

  final String? name;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = this.name;
    if (name == null) {
      return SrButton(
        label: l10n.growthEmailAttach,
        icon: Icons.attach_file_rounded,
        variant: SrButtonVariant.secondary,
        size: SrButtonSize.sm,
        onPressed: onPick,
      );
    }
    return SrCard(
      padding: EdgeInsets.zero,
      child: SrListRow(
        leading: const Icon(Icons.description_outlined),
        title: name,
        trailing: SrIconButton(
          icon: Icons.close_rounded,
          tooltip: l10n.commonClear,
          compact: true,
          onTap: onRemove,
        ),
      ),
    );
  }
}

/// The email as a recipient sees it; [sample] fills the merge fields.
class _EmailPreview extends StatelessWidget {
  const _EmailPreview({
    required this.from,
    required this.subject,
    required this.body,
    required this.attachment,
    required this.orderButton,
    this.sample = false,
  });

  final String from;
  final String subject;
  final String body;
  final String? attachment;
  final bool orderButton;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final attachment = this.attachment;
    final text = sample
        ? body
              .replaceAll('{{name}}', l10n.growthEmailSampleName)
              .replaceAll('{{company}}', l10n.growthEmailSampleCompany)
        : body;
    return SrCard(
      tone: SrCardTone.dashed,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SrAvatar(
                name: from,
                square: true,
                size: 30,
                tone: SrAvatarTone.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  from,
                  style: AppText.rowTitle(c.ink, size: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subject.isEmpty ? l10n.growthEmailNoSubject : subject,
            style: AppText.rowTitle(subject.isEmpty ? c.ink3 : c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            text.isEmpty ? l10n.growthEmailNoBody : text,
            style: AppText.body(text.isEmpty ? c.ink3 : c.ink, size: 13),
          ),
          if (attachment != null) ...[
            const SizedBox(height: 8),
            SrTag(attachment, icon: Icons.attach_file_rounded),
          ],
          if (orderButton) ...[
            const SizedBox(height: 10),
            SrTag(
              l10n.growthEmailPlaceOrder,
              tone: SrTone.accent,
              icon: Icons.shopping_cart_outlined,
            ),
          ],
        ],
      ),
    );
  }
}
