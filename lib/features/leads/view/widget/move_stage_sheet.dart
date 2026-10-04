import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lost_reason_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Runs #30 → #31 → save: pick a stage (or take [to]), give a reason when
/// it is Lost, then move [lead]; [origin] shows the undo snackbar.
Future<void> moveLeadStage(
  BuildContext context,
  WidgetRef ref,
  Lead lead,
  LeadSurface origin, {
  LeadStage? to,
}) async {
  final actions = ref.read(leadActionsProvider.notifier);
  final target =
      to ??
      await showSrSheet<LeadStage>(
        context: context,
        builder: (_) => MoveStageSheet(lead: lead),
      );
  if (target == null || target.id == lead.stage?.id || !context.mounted) {
    return;
  }
  if (!target.isLost) return actions.moveStage(lead, target, origin);
  final reason = await showSrSheet<LostReasonChoice>(
    context: context,
    builder: (_) => const LostReasonSheet(),
  );
  if (reason == null) return;
  await actions.moveStage(
    lead,
    target,
    origin,
    lostReasonId: reason.reasonId,
    note: reason.note,
  );
}

/// #30: the stages a lead can move to, with Lost and Won as buttons.
class MoveStageSheet extends ConsumerWidget {
  const MoveStageSheet({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = ref.watch(leadStagesProvider).value ?? const <LeadStage>[];
    return SrSheet(
      title: l10n.leadsMoveStage,
      subtitle: lead.leadName,
      child: SrAsyncView(
        value: ref.watch(visibleLeadStagesProvider),
        loading: (_) => const SrSkeletonList(count: 4, shrinkWrap: true),
        onRetry: () => ref.invalidate(leadStagesProvider),
        data: (context, stages) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SrCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Column(
                  children: [
                    for (final (i, stage) in stages.indexed)
                      _StageRow(
                        stage: stage,
                        current: stage.id == lead.stage?.id,
                        divider: i < stages.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OutcomeButtons(lost: all.lost, won: all.won),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.current,
    required this.divider,
  });

  final LeadStage stage;
  final bool current;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final bangla = context.fmt.isBangla;
    final hint = stage.hint.of(bangla);
    return SrListRow(
      title: stage.name.of(bangla),
      subtitle: hint.isEmpty ? null : hint,
      divider: divider,
      padding: const EdgeInsets.symmetric(vertical: 10),
      leading: current
          ? const SrAvatar(icon: Icons.check_rounded, tone: SrAvatarTone.accent)
          : Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.avatarBg,
                border: SrBorder.all(color: c.line),
              ),
            ),
      trailing: SrTag(
        context.fmt.percent(stage.winProbability),
        tone: stage.isWon ? SrTone.ok : SrTone.neutral,
      ),
      onTap: () => Navigator.of(context).pop(stage),
    );
  }
}

class _OutcomeButtons extends StatelessWidget {
  const _OutcomeButtons({required this.lost, required this.won});

  final LeadStage? lost;
  final LeadStage? won;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lost = this.lost;
    final won = this.won;
    return Row(
      children: [
        if (lost != null)
          Expanded(
            child: SrButton(
              label: l10n.leadsLost,
              variant: SrButtonVariant.danger,
              expand: true,
              onPressed: () => Navigator.of(context).pop(lost),
            ),
          ),
        if (lost != null && won != null) const SizedBox(width: 10),
        if (won != null)
          Expanded(
            child: SrButton(
              label: l10n.leadsWon,
              expand: true,
              onPressed: () => Navigator.of(context).pop(won),
            ),
          ),
      ],
    );
  }
}
