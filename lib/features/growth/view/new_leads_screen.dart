import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #136 New leads from every channel, with the SLA timer.
class NewLeadsScreen extends ConsumerWidget {
  const NewLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(inboxListProvider);
    final average = list.value?.facets['Stats']?['AvgFirstResponseMinutes'];
    final rules = ref.watch(moduleAccessProvider(AppModule.distribution));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthInboxTitle,
        subtitle: average == null || average == 0
            ? null
            : l10n.growthInboxAverage(context.fmt.number(average)),
        actions: [
          const GrowthLanguageAction(),
          if (rules.visible)
            SrIconButton(
              icon: Icons.tune_rounded,
              tooltip: l10n.growthRulesTitle,
              onTap: () => context.push(Routes.distribution),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _FilterChips(),
          ),
          Expanded(
            child: SrAsyncView(
              value: list,
              onRetry: () => ref.invalidate(inboxListProvider),
              onUpgrade: () => context.push(Routes.planUsage),
              data: (context, paged) => GrowthClock(
                builder: (context) => GrowthPagedList<InboxLead>(
                  paged: paged,
                  onLoadMore: () =>
                      ref.read(inboxListProvider.notifier).loadMore(),
                  onRefresh: () =>
                      ref.read(inboxListProvider.notifier).refresh(),
                  empty: const _Empty(),
                  row: (lead) => _InboxRow(lead: lead),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(inboxFilterProvider);
    final counts = ref.watch(
      inboxListProvider.select((list) => list.value?.facets['Counts']),
    );
    final filters = InboxFilter.values;
    return SrChipRow(
      index: filters.indexOf(filter),
      onChanged: (i) => ref.read(inboxFilterProvider.notifier).set(filters[i]),
      chips: [
        for (final f in filters)
          SrChipItem(
            switch (f) {
              InboxFilter.all => l10n.commonAll,
              InboxFilter.unassigned => l10n.growthInboxUnassigned,
              InboxFilter.mine => l10n.growthInboxMine,
              InboxFilter.late => l10n.growthInboxLateFilter,
              InboxFilter.facebook => l10n.growthSourceFacebook,
              InboxFilter.website => l10n.growthSourceWebsite,
              InboxFilter.whatsapp => l10n.growthSourceWhatsapp,
            },
            count: counts?[f.wire],
            tone: f == InboxFilter.late ? SrTone.err : SrTone.neutral,
          ),
      ],
    );
  }
}

class _InboxRow extends ConsumerWidget {
  const _InboxRow({required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final canEdit = ref.watch(moduleAccessProvider(AppModule.inbox)).canEdit;
    final area = lead.area?.of(fmt.isBangla);
    final late = lead.isLate();
    return SrListRow(
      leading: SrAvatar(
        name: lead.name,
        tone: lead.duplicate != null
            ? SrAvatarTone.gold
            : lead.status == InboxStatus.fresh && !late
            ? SrAvatarTone.accent
            : SrAvatarTone.neutral,
      ),
      title: area == null ? lead.name : '${lead.name} · $area',
      subtitle: [
        lead.source.label(l10n),
        if (lead.duplicate != null)
          l10n.growthInboxMatchesExisting
        else
          ?(lead.interest ?? lead.formName),
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            growthAgo(context, lead.waiting()),
            style: AppText.meta(late ? c.danger : c.ink2, size: 12),
          ),
          const SizedBox(height: 4),
          InboxStatusTag(lead: lead),
        ],
      ),
      onTap: () => context.push(Routes.newLeadFor(lead.id)),
      onLongPress: canEdit && lead.canEdit
          ? () => showInboxQuickActions(context, ref, lead)
          : null,
    );
  }
}

/// New, late, possible duplicate or who it is assigned to.
class InboxStatusTag extends StatelessWidget {
  const InboxStatusTag({super.key, required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final assignee = lead.assignedTo?.of(context.fmt.isBangla);
    return switch (lead.status) {
      InboxStatus.accepted => SrTag(
        l10n.growthInboxAcceptedTag,
        tone: SrTone.ok,
      ),
      InboxStatus.rejected => SrTag(l10n.growthInboxRejectedTag),
      InboxStatus.assigned => SrTag(
        l10n.growthInboxAssignedTag(assignee?.split(' ').first ?? ''),
      ),
      InboxStatus.fresh when lead.duplicate != null => SrTag(
        l10n.growthInboxDuplicateTag,
        tone: SrTone.warn,
      ),
      InboxStatus.fresh when lead.isLate() => SrTag(
        l10n.growthInboxLateTag,
        tone: SrTone.err,
      ),
      InboxStatus.fresh => SrTag(l10n.growthInboxNewTag, tone: SrTone.ok),
    };
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sources = ref.watch(moduleAccessProvider(AppModule.leadSources));
    return SrEmptyState(
      icon: Icons.move_to_inbox_outlined,
      title: l10n.growthInboxEmpty,
      message: l10n.growthInboxEmptyBody,
      actionLabel: sources.visible ? l10n.growthInboxConnectChannels : null,
      onAction: sources.visible
          ? () => context.push(Routes.growthChannels)
          : null,
    );
  }
}
