import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/call_outcome_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_card.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/lead_launcher.dart';
import 'package:salesroot/features/leads/view/widget/lead_timeline.dart';
import 'package:salesroot/features/leads/view/widget/move_stage_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #28: one lead — stage, contact actions, deal, next task and timeline.
class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(leadProvider(id));
    final lead = value.value;
    final locale = ref.watch(appLocaleProvider);
    final buttons = lead == null
        ? const <Widget>[]
        : _footerButtons(context, ref, lead);
    listenLeadEvents(
      context,
      ref,
      LeadSurface.detail,
      onDeleted: () => context.pop(),
    );
    return LeadCallWatcher(
      child: SrScaffold(
        appBar: SrAppBar(
          titleWidget: Center(
            child: Text(
              l10n.leadsDetailTitle,
              style: AppText.rowTitle(SrColors.of(context).ink2, size: 14),
            ),
          ),
          actions: [
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
            if (lead != null)
              SrIconButton(
                icon: Icons.more_vert_rounded,
                tooltip: l10n.commonMore,
                onTap: () => _menu(context, ref, lead),
              ),
          ],
        ),
        body: SrAsyncView(
          value: value,
          loading: (_) => const SrSkeletonList(cards: true, count: 4),
          onRetry: () => ref.invalidate(leadProvider(id)),
          data: (context, lead) => RefreshIndicator(
            onRefresh: () => ref.refresh(leadProvider(id).future),
            child: _Body(lead: lead),
          ),
        ),
        footer: buttons.isEmpty
            ? null
            : Row(
                children: [
                  for (final (i, button) in buttons.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: button),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, Lead lead) async {
    final action = await showSrSheet<_DetailAction>(
      context: context,
      builder: (_) => _DetailMenu(lead: lead),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _DetailAction.links:
        context.push(Routes.leadLinksFor(lead.id));
      case _DetailAction.edit:
        context.push(Routes.leadEditFor(lead.id));
      case _DetailAction.log:
        context.push(Routes.leadActivityFor(lead.id));
      case _DetailAction.discuss:
        context.push('${Routes.chats}?leadId=${lead.id}');
      case _DetailAction.delete:
        final actions = ref.read(leadActionsProvider.notifier);
        if (await confirmLeadDelete(context, lead)) {
          await actions.delete(lead, LeadSurface.detail);
        }
    }
  }
}

enum _DetailAction { links, edit, log, discuss, delete }

class _DetailMenu extends ConsumerWidget {
  const _DetailMenu({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.lead));
    final chat = ref.watch(moduleAccessProvider(AppModule.chat));
    final editable = access.canEdit && lead.canEdit;
    final rows = [
      (_DetailAction.links, Icons.link_rounded, l10n.leadsDetails),
      if (editable) ...[
        (_DetailAction.edit, Icons.edit_outlined, l10n.commonEdit),
        (_DetailAction.log, Icons.edit_note_rounded, l10n.leadsLogActivity),
      ],
      if (chat.canView)
        (_DetailAction.discuss, Icons.forum_outlined, l10n.leadsDiscuss),
      if (access.canDelete && lead.canDelete)
        (_DetailAction.delete, Icons.delete_outline_rounded, l10n.commonDelete),
    ];
    return SrSheet(
      title: lead.leadName,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (action, icon, label) in rows)
              SrListRow(
                title: label,
                leading: SrAvatar(
                  icon: icon,
                  size: 36,
                  tone: action == _DetailAction.delete
                      ? SrAvatarTone.danger
                      : SrAvatarTone.neutral,
                ),
                onTap: () => Navigator.of(context).pop(action),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editable =
        ref.watch(moduleAccessProvider(AppModule.lead)).canEdit && lead.canEdit;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(lead: lead),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StageStrip(lead: lead, editable: editable),
              const SizedBox(height: 12),
              _ContactTiles(lead: lead),
              const SizedBox(height: 12),
              _Deal(lead: lead),
              const SizedBox(height: 12),
              _NextTask(lead: lead, editable: editable),
              const SizedBox(height: 18),
              SrSectionHeader(
                title: l10n.leadsTimeline,
                actionLabel: editable ? l10n.leadsAddNote : null,
                onAction: editable
                    ? () => context.push(
                        '${Routes.leadActivityFor(lead.id)}'
                        '?type=${LeadActivityKind.note.query}',
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              LeadTimeline(lead: lead),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final temperature = lead.temperature;
    final contact = lead.primaryContact;
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: () => context.push(Routes.leadLinksFor(lead.id)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            6,
            SrMetrics.gutter,
            16,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              SrAvatar(name: lead.leadName, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.leadName,
                      style: AppText.pageTitle(c.ink, size: 20),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      leadMeta([
                        contact?.name,
                        contact?.designation,
                        lead.company?.area?.of(bangla),
                      ]),
                      style: AppText.meta(c.ink2, size: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SrTag(lead.stageName(bangla), tone: lead.stageTone),
                        if (temperature != null)
                          SrTag(
                            temperature.label(l10n),
                            tone: temperature.tone,
                          ),
                        for (final tag in lead.tags) SrTag(tag.name.of(bangla)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageStrip extends ConsumerWidget {
  const _StageStrip({required this.lead, required this.editable});

  final Lead lead;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final all = ref.watch(leadStagesProvider).value ?? const <LeadStage>[];
    final visible = ref.watch(visibleLeadStagesProvider).value ?? const [];
    if (lead.isLost) {
      final loss = lead.winLoss;
      return SrNote(
        tone: SrNoteTone.err,
        icon: Icons.thumb_down_alt_outlined,
        title: lead.stageName(bangla),
        message: leadMeta([loss?.cause?.of(bangla), loss?.note]),
        action: editable
            ? SrButton(
                label: l10n.leadsReopen,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                onPressed: () =>
                    moveLeadStage(context, ref, lead, LeadSurface.detail),
              )
            : null,
      );
    }
    final position = all.positionIn(visible, lead.stage?.id);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: editable
          ? () => moveLeadStage(context, ref, lead, LeadSurface.detail)
          : null,
      child: SrSegmentBar(
        segments: visible.length,
        filled: position + 1,
        labels: [for (final s in visible) s.name.of(bangla)],
        current: position,
        color: lead.isWon ? c.success : null,
      ),
    );
  }
}

class _ContactTiles extends ConsumerWidget {
  const _ContactTiles({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final phone = lead.phone;
    final email = lead.email;

    Future<void> open(
      Future<bool> Function() launch,
      LeadActivityKind kind,
    ) async {
      final opened = await launch();
      if (!context.mounted) return;
      if (!opened) {
        showSrError(context, l10n.leadsLaunchFailed);
        return;
      }
      showSrSnack(
        context,
        l10n.leadsLogPrompt,
        action: SrSnackAction(
          label: l10n.leadsLogIt,
          onPressed: () => context.push(
            '${Routes.leadActivityFor(lead.id)}?type=${kind.query}',
          ),
        ),
        duration: const Duration(seconds: 6),
      );
    }

    void noPhone() => showSrWarning(context, l10n.leadsNoPhone);

    return Row(
      children: [
        _Tile(
          icon: Icons.call_outlined,
          label: l10n.commonCall,
          onTap: () => callLead(context, ref, lead),
        ),
        const SizedBox(width: 8),
        _Tile(
          icon: Icons.chat_outlined,
          label: l10n.leadsKindWhatsapp,
          onTap: phone == null
              ? noPhone
              : () => open(
                  () => LeadLauncher.whatsapp(phone),
                  LeadActivityKind.whatsapp,
                ),
        ),
        const SizedBox(width: 8),
        _Tile(
          icon: Icons.sms_outlined,
          label: l10n.leadsKindSms,
          onTap: phone == null
              ? noPhone
              : () => open(() => LeadLauncher.sms(phone), LeadActivityKind.sms),
        ),
        const SizedBox(width: 8),
        _Tile(
          icon: Icons.mail_outline_rounded,
          label: l10n.leadsKindEmail,
          onTap: email == null
              ? () => showSrWarning(context, l10n.leadsNoEmail)
              : () => open(
                  () => LeadLauncher.email(email),
                  LeadActivityKind.email,
                ),
        ),
      ],
    );
  }
}

/// The prototype's `.tile`: an icon over a short label.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Expanded(
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              children: [
                Icon(icon, size: 20, color: c.accent),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Deal extends StatelessWidget {
  const _Deal({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final amount = lead.estimatedAmount;
    final quoted = lead.lastQuotation?.amount;
    final win = lead.winProbability;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: LeadFact(
                    label: l10n.leadsDealValue,
                    value: amount == null
                        ? l10n.leadsNone
                        : fmt.moneyCompact(amount),
                    size: 15,
                  ),
                ),
                VerticalDivider(width: 24, color: c.line),
                Expanded(
                  child: LeadFact(
                    label: l10n.leadsLastQuoted,
                    value: quoted == null
                        ? l10n.leadsNone
                        : fmt.moneyCompact(quoted),
                    size: 15,
                  ),
                ),
                VerticalDivider(width: 24, color: c.line),
                Expanded(
                  child: LeadFact(
                    label: l10n.leadsWin,
                    value: fmt.percent(win),
                    color: lead.isLost ? c.danger : c.success,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SrProgressBar(value: win / 100, color: lead.isLost ? c.danger : null),
          const SizedBox(height: 10),
          _CloseLine(lead: lead),
        ],
      ),
    );
  }
}

class _CloseLine extends StatelessWidget {
  const _CloseLine({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final closing = lead.estimatedClosingDate;
    final days = lead.daysToClose;
    final tag = !lead.isOpen || closing == null || days == null
        ? null
        : days > 0
        ? SrTag(
            l10n.leadsInDays(fmt.number(days)),
            tone: days <= 7 ? SrTone.warn : SrTone.neutral,
          )
        : days == 0
        ? SrTag(l10n.commonToday, tone: SrTone.warn)
        : SrTag(l10n.leadsDaysLate(fmt.number(-days)), tone: SrTone.err);
    return Row(
      children: [
        Icon(Icons.event_outlined, size: 16, color: c.ink2),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            closing == null
                ? l10n.leadsNoCloseDate
                : l10n.leadsClosesOn(fmt.date(closing)),
            style: AppText.meta(c.ink2),
          ),
        ),
        ?tag,
      ],
    );
  }
}

class _NextTask extends ConsumerWidget {
  const _NextTask({required this.lead, required this.editable});

  final Lead lead;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final at = lead.nextTaskAt;
    if (!lead.hasNextTask) {
      final canPlan = ref.watch(moduleAccessProvider(AppModule.task)).canAdd;
      if (!lead.isOpen) return const SizedBox.shrink();
      return SrNote(
        tone: SrNoteTone.neutral,
        icon: Icons.event_busy_outlined,
        message: l10n.leadsNoNextTask,
        action: canPlan
            ? SrButton(
                label: l10n.leadsPlanTask,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                onPressed: () => context.push(
                  Uri(
                    path: Routes.taskNew,
                    queryParameters: {
                      'leadId': '${lead.id}',
                      'title': lead.leadName,
                    },
                  ).toString(),
                ),
              )
            : null,
      );
    }
    return SrNote(
      tone: lead.isOverdue ? SrNoteTone.err : SrNoteTone.tint,
      icon: Icons.event_outlined,
      title: l10n.leadsNextTask,
      message: leadMeta([
        at == null ? null : leadDayTime(context, at),
        lead.nextTaskTitle ?? lead.nextTaskType?.label(l10n),
      ]),
      action: editable
          ? SrButton(
              label: l10n.commonDone,
              size: SrButtonSize.sm,
              onPressed: () => ref
                  .read(leadActionsProvider.notifier)
                  .completeTask(lead, LeadSurface.detail),
            )
          : null,
    );
  }
}

/// Move stage and Create quotation, each when the user may.
List<Widget> _footerButtons(BuildContext context, WidgetRef ref, Lead lead) {
  final l10n = context.l10n;
  final editable =
      ref.watch(moduleAccessProvider(AppModule.lead)).canEdit && lead.canEdit;
  final canQuote =
      lead.isOpen &&
      ref.watch(moduleAccessProvider(AppModule.quotation)).canAdd;
  return [
    if (editable)
      SrButton(
        label: l10n.leadsMoveStage,
        variant: SrButtonVariant.secondary,
        expand: true,
        onPressed: () => moveLeadStage(context, ref, lead, LeadSurface.detail),
      ),
    if (canQuote)
      SrButton(
        label: l10n.leadsCreateQuotation,
        expand: true,
        onPressed: () =>
            context.push('${Routes.quotationNew}?leadId=${lead.id}'),
      ),
  ];
}
