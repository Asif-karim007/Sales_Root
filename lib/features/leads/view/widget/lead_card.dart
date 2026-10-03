import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/call_outcome_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/lead_launcher.dart';
import 'package:salesroot/features/leads/view/widget/move_stage_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// One lead in the list (#21). In pick mode a tap hands the lead to
/// [onPick] and the actions are hidden.
class LeadCard extends ConsumerWidget {
  const LeadCard({super.key, required this.lead, this.onPick});

  final Lead lead;
  final ValueChanged<Lead>? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final access = ref.watch(moduleAccessProvider(AppModule.lead));
    final onPick = this.onPick;
    final editable = access.canEdit && lead.canEdit;
    void open() =>
        onPick != null ? onPick(lead) : context.push(Routes.leadFor(lead.id));

    return SrCard(
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.leadName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowTitle(c.ink, size: 15.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.contactLine(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta(c.ink2),
                    ),
                  ],
                ),
              ),
              if (onPick == null)
                SrIconButton(
                  icon: Icons.more_vert_rounded,
                  compact: true,
                  color: c.ink3,
                  tooltip: context.l10n.commonMore,
                  onTap: () =>
                      showLeadMenu(context, ref, lead, LeadSurface.list),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LeadStageButton(
                  lead: lead,
                  onTap: editable && onPick == null
                      ? () =>
                            moveLeadStage(context, ref, lead, LeadSurface.list)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              SrRing(value: lead.winProbability / 100),
            ],
          ),
          const SizedBox(height: 10),
          _Facts(lead: lead),
          if (onPick == null) ...[
            const SizedBox(height: 10),
            _Actions(lead: lead),
          ],
        ],
      ),
    );
  }
}

/// The prototype's stage field: "Stage · tap to change" over the stage name.
class LeadStageButton extends StatelessWidget {
  const LeadStageButton({super.key, required this.lead, this.onTap});

  final Lead lead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final tone = lead.stageTone;
    return Material(
      color: c.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusButton),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusButton),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        onTap == null
                            ? l10n.leadsStage
                            : l10n.leadsStageTapToChange,
                        style: AppText.label(c.ink2, size: 11),
                      ),
                      Text(
                        lead.stageName(context.fmt.isBangla),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.rowTitle(tone.foreground(c), size: 13.5),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.expand_more_rounded, size: 18, color: c.ink2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final amount = lead.estimatedAmount;
    final next = lead.nextLine(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: LeadFact(
              label: l10n.leadsDealValue,
              value: amount == null
                  ? l10n.leadsNone
                  : context.fmt.moneyCompact(amount),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LeadFact(
              label: l10n.leadsNext,
              value: next ?? l10n.leadsNoNextStep,
              color: lead.isOverdue ? c.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small label over a bold value, the prototype's `.kpi`.
class LeadFact extends StatelessWidget {
  const LeadFact({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.size = 13.5,
  });

  final String label;
  final String value;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label(c.ink2)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.rowTitle(color ?? c.ink, size: size),
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final canVisit = ref.watch(moduleAccessProvider(AppModule.visit)).canAdd;
    final canLog =
        ref.watch(moduleAccessProvider(AppModule.lead)).canEdit && lead.canEdit;
    final phone = lead.phone;
    return Row(
      children: [
        Expanded(
          child: canVisit
              ? SrButton(
                  label: l10n.leadsStartVisit,
                  icon: Icons.place_outlined,
                  size: SrButtonSize.sm,
                  expand: true,
                  onPressed: () =>
                      context.push('${Routes.visits}?new=1&leadId=${lead.id}'),
                )
              : SrButton(
                  label: l10n.leadsLogActivity,
                  icon: Icons.edit_note_rounded,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  expand: true,
                  onPressed: canLog
                      ? () => context.push(
                          '${Routes.leadActivityFor(lead.id)}'
                          '?type=${LeadActivityKind.call.query}',
                        )
                      : null,
                ),
        ),
        const SizedBox(width: 8),
        SrIconButton(
          icon: Icons.call_outlined,
          color: c.accent,
          tooltip: l10n.commonCall,
          onTap: () => callLead(context, ref, lead),
        ),
        const SizedBox(width: 8),
        SrIconButton(
          icon: Icons.chat_outlined,
          color: c.accent,
          tooltip: l10n.leadsKindWhatsapp,
          onTap: phone == null
              ? () => showSrWarning(context, l10n.leadsNoPhone)
              : () async {
                  final opened = await LeadLauncher.whatsapp(phone);
                  if (!opened && context.mounted) {
                    showSrError(context, l10n.leadsLaunchFailed);
                  }
                },
        ),
      ],
    );
  }
}

enum LeadMenuAction { open, moveStage, log, edit, delete }

/// Opens the ⋮ menu for [lead] and carries out the chosen action.
Future<void> showLeadMenu(
  BuildContext context,
  WidgetRef ref,
  Lead lead,
  LeadSurface origin,
) async {
  final action = await showSrSheet<LeadMenuAction>(
    context: context,
    builder: (_) => LeadMenuSheet(lead: lead),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case LeadMenuAction.open:
      context.push(Routes.leadFor(lead.id));
    case LeadMenuAction.moveStage:
      await moveLeadStage(context, ref, lead, origin);
    case LeadMenuAction.log:
      context.push(Routes.leadActivityFor(lead.id));
    case LeadMenuAction.edit:
      context.push(Routes.leadEditFor(lead.id));
    case LeadMenuAction.delete:
      final actions = ref.read(leadActionsProvider.notifier);
      if (await confirmLeadDelete(context, lead)) {
        await actions.delete(lead, origin);
      }
  }
}

/// The ⋮ menu: open, move stage, log, edit and delete, each shown only when
/// the role and the lead allow it. Pops with a [LeadMenuAction].
class LeadMenuSheet extends ConsumerWidget {
  const LeadMenuSheet({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.lead));
    final editable = access.canEdit && lead.canEdit;
    final deletable = access.canDelete && lead.canDelete;
    final rows = [
      (LeadMenuAction.open, Icons.open_in_new_rounded, l10n.leadsOpen),
      if (editable) ...[
        (
          LeadMenuAction.moveStage,
          Icons.trending_flat_rounded,
          l10n.leadsMoveStage,
        ),
        (LeadMenuAction.log, Icons.edit_note_rounded, l10n.leadsLogActivity),
        (LeadMenuAction.edit, Icons.edit_outlined, l10n.commonEdit),
      ],
      if (deletable)
        (
          LeadMenuAction.delete,
          Icons.delete_outline_rounded,
          l10n.commonDelete,
        ),
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
                  tone: action == LeadMenuAction.delete
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

Future<bool> confirmLeadDelete(BuildContext context, Lead lead) {
  final l10n = context.l10n;
  return showSrConfirm(
    context,
    title: l10n.leadsDeleteTitle,
    message: l10n.leadsDeleteBody(lead.leadName),
    confirmLabel: l10n.commonDelete,
    icon: Icons.delete_outline_rounded,
    destructive: true,
  );
}
