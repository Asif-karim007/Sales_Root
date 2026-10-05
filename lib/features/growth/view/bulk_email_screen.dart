import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/view/widget/audience_field.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/merge_tags.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #145 Write a bulk email to a segment. The subject names the campaign.
class BulkEmailScreen extends ConsumerStatefulWidget {
  const BulkEmailScreen({super.key});

  @override
  ConsumerState<BulkEmailScreen> createState() => _BulkEmailScreenState();
}

class _BulkEmailScreenState extends ConsumerState<BulkEmailScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  AudienceSegment _segment = AudienceSegment.customers;

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
    final submit = ref.watch(campaignSubmitProvider);
    ref.listen(campaignSubmitProvider, _onSubmit);
    final audiences = ref.watch(
      campaignAudiencesProvider(CampaignChannel.email),
    );
    final from = ref.watch(currentWorkspaceProvider)?.name ?? '';
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
        onRetry: () =>
            ref.invalidate(campaignAudiencesProvider(CampaignChannel.email)),
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
                error: failure?.fieldError('name'),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SrTextField(
                controller: _body,
                label: l10n.growthEmailBody,
                hint: l10n.growthEmailBodyHint,
                multiline: true,
                error: failure?.fieldError('body'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              MergeTags(
                tags: const ['{{name}}', '{{company}}'],
                controller: _body,
                onInserted: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _EmailPreview(
                from: from,
                subject: _subject.text,
                body: _body.text,
              ),
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
              onPressed: () => _preview(from),
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

  void _submit() => ref
      .read(campaignSubmitProvider.notifier)
      .submit(
        CampaignInput(
          name: _subject.text,
          channel: CampaignChannel.email,
          segment: _segment,
          body: _body.text,
        ),
      );

  void _preview(String from) => showSrSheet<void>(
    context: context,
    builder: (context) => SrSheet(
      title: context.l10n.growthEmailPreview,
      child: SingleChildScrollView(
        child: _EmailPreview(
          from: from,
          subject: _subject.text,
          body: _body.text,
          sample: true,
        ),
      ),
    ),
  );

  void _onSubmit(AsyncValue<Campaign?>? _, AsyncValue<Campaign?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncError(:final ApiFailure error)
          when error.isValidation && error.fieldErrors.isNotEmpty:
        return;
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

/// The email as a recipient sees it; [sample] fills the merge fields.
class _EmailPreview extends StatelessWidget {
  const _EmailPreview({
    required this.from,
    required this.subject,
    required this.body,
    this.sample = false,
  });

  final String from;
  final String subject;
  final String body;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
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
        ],
      ),
    );
  }
}
