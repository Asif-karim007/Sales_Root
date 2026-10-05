import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/sms_count.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/view/widget/audience_field.dart';
import 'package:salesroot/features/growth/view/widget/campaign_text.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/merge_tags.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #144 Write a bulk SMS: audience, message with segment counting, credit
/// cost and schedule.
class BulkSmsScreen extends ConsumerStatefulWidget {
  const BulkSmsScreen({super.key});

  @override
  ConsumerState<BulkSmsScreen> createState() => _BulkSmsScreenState();
}

class _BulkSmsScreenState extends ConsumerState<BulkSmsScreen> {
  final _message = TextEditingController();
  AudienceSegment _segment = AudienceSegment.openLeads;
  MessageTemplate? _template;
  bool _sendNow = false;
  DateTime _scheduleAt = _tomorrowAtTen();

  static DateTime _tomorrowAtTen() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 10);
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submit = ref.watch(campaignSubmitProvider);
    ref.listen(campaignSubmitProvider, _onSubmit);
    final audiences = ref.watch(campaignAudiencesProvider(CampaignChannel.sms));
    final credits = ref.watch(smsCreditsProvider).value;
    final audience = audiences.value
        ?.where((a) => a.segment == _segment)
        .firstOrNull;
    final reach = audience?.count ?? 0;
    final count = SmsCount.of(_message.text);
    final needed = count.segments * reach;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthCampaignsBulkSms,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: audiences,
        onRetry: () =>
            ref.invalidate(campaignAudiencesProvider(CampaignChannel.sms)),
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
              SrDropdownField(
                label: l10n.growthSmsTemplate,
                value: _template?.name,
                placeholder: l10n.growthSmsNoTemplate,
                onTap: _pickTemplate,
              ),
              const SizedBox(height: 12),
              SrTextField(
                controller: _message,
                label: l10n.growthSmsMessage,
                hint: l10n.growthSmsMessageHint,
                multiline: true,
                error: _messageError(submit),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              MergeTags(
                tags: const ['{{name}}', '{{bill}}', '{{due}}', '{{date}}'],
                controller: _message,
                onInserted: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _CostCard(
                count: count,
                needed: needed,
                credits: credits,
                cost: audience?.estimatedCost,
              ),
              if (credits != null && needed > credits) ...[
                const SizedBox(height: 12),
                _ShortNote(needed: needed, have: credits),
              ],
              const SizedBox(height: 12),
              _ScheduleCard(
                sendNow: _sendNow,
                scheduleAt: _scheduleAt,
                onSendNow: (v) => setState(() => _sendNow = v),
                onSchedule: (at) => setState(() => _scheduleAt = at),
              ),
            ],
          ),
        ),
      ),
      footer: SrButton(
        label: _sendNow
            ? l10n.growthSmsSendTo(context.fmt.number(reach))
            : l10n.growthSmsScheduleFor(context.fmt.number(reach)),
        expand: true,
        loading: submit.isLoading,
        onPressed: reach == 0 ? null : _submit,
      ),
    );
  }

  String? _messageError(AsyncValue<Campaign?> submit) => switch (submit) {
    AsyncError(:final ApiFailure error) => error.fieldError('body'),
    _ => null,
  };

  void _submit() {
    final message = _message.text.trim();
    final words = message.split(RegExp(r'\s+')).take(4).join(' ');
    ref
        .read(campaignSubmitProvider.notifier)
        .submit(
          CampaignInput(
            name: _template?.name ?? words,
            channel: CampaignChannel.sms,
            segment: _segment,
            body: message,
            templateId: _template?.id,
            scheduledAt: _sendNow ? null : _scheduleAt,
          ),
        );
  }

  void _onSubmit(AsyncValue<Campaign?>? _, AsyncValue<Campaign?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncError(:final ApiFailure error) when error.isQuota:
        showSrWarning(context, l10n.growthSmsNotEnough);
        context.push(Routes.campaignCredits);
      case AsyncError(:final ApiFailure error)
          when error.fieldError('body') != null:
        return;
      case AsyncError(:final error):
        showSrError(context, growthFailureText(context, error));
      case AsyncData(:final value?):
        showSrSuccess(
          context,
          value.status == CampaignStatus.scheduled
              ? l10n.growthSmsScheduled(context.fmt.number(value.recipients))
              : l10n.growthSmsSent(context.fmt.number(value.recipients)),
        );
        context.pop();
      default:
        return;
    }
  }

  Future<void> _pickTemplate() async {
    final l10n = context.l10n;
    final templates = await runGrowthAction(
      context,
      ref.read(smsTemplatesProvider.future),
    );
    if (templates == null || !mounted) return;
    final picked = await showSrSheet<MessageTemplate>(
      context: context,
      builder: (_) => SrOptionSheet<MessageTemplate>(
        title: l10n.growthSmsTemplate,
        options: templates,
        labelOf: (t) => t.name,
        subtitleOf: (t) => t.body,
        isSelected: (t) => t.id == _template?.id,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _template = picked;
      _message.text = picked.body;
    });
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard({
    required this.count,
    required this.needed,
    required this.credits,
    required this.cost,
  });

  final SmsCount count;
  final int needed;
  final int? credits;

  /// The server's estimate for the whole send, in taka.
  final double? cost;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final credits = this.credits;
    final cost = this.cost;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          GrowthInfoLine(
            label: l10n.growthSmsCharacters,
            value: smsLengthLine(context, count),
          ),
          GrowthInfoLine(
            label: l10n.growthSmsPerPerson,
            value: fmt.number(count.segments),
          ),
          GrowthInfoLine(
            label: l10n.growthSmsCredits,
            value: credits == null
                ? fmt.number(needed)
                : l10n.growthCampaignOf(
                    fmt.number(needed),
                    fmt.number(credits),
                  ),
            valueColor: credits != null && needed > credits ? c.danger : null,
            divider: cost != null,
          ),
          if (cost != null)
            GrowthInfoLine(
              label: l10n.growthSmsEstimatedCost,
              value: fmt.money(cost),
              divider: false,
            ),
        ],
      ),
    );
  }
}

class _ShortNote extends StatelessWidget {
  const _ShortNote({required this.needed, required this.have});

  final int needed;
  final int have;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrNote(
      tone: SrNoteTone.err,
      message: l10n.growthSmsShort(fmt.number(needed), fmt.number(have)),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.sendNow,
    required this.scheduleAt,
    required this.onSendNow,
    required this.onSchedule,
  });

  final bool sendNow;
  final DateTime scheduleAt;
  final ValueChanged<bool> onSendNow;
  final ValueChanged<DateTime> onSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrCard(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          GrowthToggleRow(
            title: l10n.growthSmsSendNow,
            subtitle: l10n.growthSmsOrSchedule,
            value: sendNow,
            onChanged: onSendNow,
          ),
          if (!sendNow)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SrDropdownField(
                label: l10n.growthSmsSchedule,
                value: context.fmt.dayTime(scheduleAt),
                icon: Icons.event_outlined,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showSrDatePicker(
                    context: context,
                    initial: scheduleAt,
                    withTime: true,
                    first: now,
                    last: now.add(const Duration(days: 90)),
                  );
                  if (picked != null) onSchedule(picked);
                },
              ),
            ),
        ],
      ),
    );
  }
}
