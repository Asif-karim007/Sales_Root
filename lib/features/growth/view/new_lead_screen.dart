import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/view/widget/accept_lead_sheet.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #137 One new lead; with [openAccept] (#138) the accept sheet opens as
/// soon as it loads.
class NewLeadScreen extends ConsumerStatefulWidget {
  const NewLeadScreen({super.key, required this.id, this.openAccept = false});

  final int id;
  final bool openAccept;

  @override
  ConsumerState<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends ConsumerState<NewLeadScreen> {
  bool _acceptShown = false;

  @override
  void initState() {
    super.initState();
    if (!widget.openAccept) return;
    ref.listenManual(inboxLeadProvider(widget.id), (_, next) {
      final lead = next.value;
      if (_acceptShown || lead == null || !lead.isOpen) return;
      _acceptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAcceptLeadSheet(context, lead);
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = ref.watch(inboxLeadProvider(widget.id));
    final lead = value.value;
    final access = ref.watch(moduleAccessProvider(AppModule.inbox));
    final canAct =
        lead != null && lead.isOpen && access.canEdit && lead.canEdit;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthInboxLeadTitle,
        actions: [
          const GrowthLanguageAction(),
          if (canAct)
            SrIconButton(
              icon: Icons.person_add_alt_rounded,
              tooltip: l10n.growthInboxAssign,
              onTap: () => assignInboxLead(context, ref, lead),
            ),
        ],
      ),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(inboxLeadProvider(widget.id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 4, cards: true),
        data: (context, lead) =>
            GrowthClock(builder: (context) => _Details(lead: lead)),
      ),
      footer: canAct
          ? Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.growthInboxReject,
                    variant: SrButtonVariant.danger,
                    onPressed: () async {
                      final rejected = await rejectInboxLead(
                        context,
                        ref,
                        lead,
                      );
                      if (rejected && context.mounted && context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.growthInboxAccept,
                    onPressed: () => showAcceptLeadSheet(context, lead),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        _Header(lead: lead),
        const SizedBox(height: 12),
        _Answers(lead: lead),
        const SizedBox(height: 12),
        _StatusNote(lead: lead),
        const SizedBox(height: 12),
        _DuplicateNote(lead: lead),
        const SizedBox(height: 12),
        _ContactButtons(lead: lead),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final area = lead.area?.of(fmt.isBangla);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SrAvatar(name: lead.name, tone: SrAvatarTone.accent, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.name, style: AppText.rowTitle(c.ink, size: 16)),
                Text(
                  [growthPhone(context, lead.phone), ?area].join(' · '),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          SrTag(lead.source.label(l10n), tone: SrTone.accent),
        ],
      ),
    );
  }
}

class _Answers extends StatelessWidget {
  const _Answers({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final consent = lead.consentAt;
    final received = lead.receivedAt;
    final externalId = lead.externalId;
    return GrowthInfoCard(
      lines: [
        if (lead.formName case final form?) (l10n.growthInboxForm, form),
        if (lead.campaign case final campaign?)
          (l10n.growthInboxCampaign, campaign),
        if (lead.interest case final interest?)
          (l10n.growthInboxInterest, interest),
        for (final answer in lead.answers)
          (answer.label.of(fmt.isBangla), answer.value),
        if (lead.email case final email?) (l10n.growthFieldEmail, email),
        if (lead.company case final company?)
          (l10n.growthFieldCompany, company),
        if (consent != null)
          (
            l10n.growthInboxConsent,
            l10n.growthInboxConsentYes(
              '${fmt.dayMonth(consent)} ${fmt.time(consent)}',
            ),
          ),
        if (externalId != null) (l10n.growthInboxMetaId, _short(externalId)),
        if (received != null) (l10n.growthInboxReceived, fmt.dayTime(received)),
      ],
    );
  }

  String _short(String id) => id.length > 10
      ? '${id.substring(0, 6)}…${id.substring(id.length - 2)}'
      : id;
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final assignee = lead.assignedTo?.of(fmt.isBangla) ?? '';
    final rule = lead.assignedByRule;
    return switch (lead.status) {
      InboxStatus.fresh => SrNote(
        tone: lead.isLate() ? SrNoteTone.err : SrNoteTone.neutral,
        icon: Icons.timer_outlined,
        message: l10n.growthInboxWaiting(
          growthAgo(context, lead.waiting()),
          fmt.number(lead.slaMinutes),
        ),
      ),
      InboxStatus.assigned => SrNote(
        icon: Icons.person_outline_rounded,
        message: rule == null
            ? l10n.growthInboxAssignedTo(assignee)
            : l10n.growthInboxAssignedByRule(assignee, rule),
      ),
      InboxStatus.accepted => SrNote(
        icon: Icons.check_circle_outline_rounded,
        message: l10n.growthInboxAcceptedNote(assignee),
      ),
      InboxStatus.rejected => SrNote(
        tone: SrNoteTone.neutral,
        icon: Icons.block_rounded,
        message: l10n.growthInboxRejectedNote,
      ),
    };
  }
}

class _DuplicateNote extends StatelessWidget {
  const _DuplicateNote({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duplicate = lead.duplicate;
    if (duplicate == null) {
      return SrNote(message: l10n.growthInboxNoDuplicate);
    }
    final companyId = duplicate.companyId;
    final route = switch (duplicate.kind) {
      DuplicateKind.lead => Routes.leadFor(duplicate.id),
      DuplicateKind.contact => Routes.contactFor(duplicate.id),
      DuplicateKind.customer => Routes.customerFor(companyId ?? duplicate.id),
    };
    return SrNote(
      tone: SrNoteTone.gold,
      icon: Icons.content_copy_rounded,
      title: switch (duplicate.kind) {
        DuplicateKind.lead => l10n.growthInboxDuplicateLead,
        DuplicateKind.contact => l10n.growthInboxDuplicateContact,
        DuplicateKind.customer => l10n.growthInboxDuplicateCustomer,
      },
      message: {duplicate.name, ?duplicate.companyName}.join(' · '),
      action: SrButton(
        label: l10n.growthInboxOpen,
        size: SrButtonSize.sm,
        variant: SrButtonVariant.secondary,
        onPressed: () => context.push(route),
      ),
    );
  }
}

class _ContactButtons extends ConsumerWidget {
  const _ContactButtons({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: SrButton(
            label: l10n.commonCall,
            icon: Icons.call_outlined,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: lead.phone)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrButton(
            label: l10n.growthSourceWhatsapp,
            icon: Icons.chat_rounded,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: () async {
              final id = await runGrowthAction(
                context,
                ref
                    .read(messageActionsProvider.notifier)
                    .open(phone: lead.phone, name: lead.name),
              );
              if (id != null && context.mounted) {
                context.push(Routes.messageThreadFor(id));
              }
            },
          ),
        ),
      ],
    );
  }
}
