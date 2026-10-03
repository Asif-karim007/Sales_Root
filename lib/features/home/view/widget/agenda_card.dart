import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/view/widget/stage_tone.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Today's plan: overdue and due-today work, each row opening its lead or,
/// for work without a lead, its task.
class AgendaCard extends ConsumerWidget {
  const AgendaCard({super.key, required this.items});

  final List<AgendaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canViewTasks = ref.watch(
      moduleAccessProvider(AppModule.task).select((a) => a.canView),
    );
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(title: l10n.homeAgendaTitle),
          const SizedBox(height: 8),
          SrCard(
            child: SrEmptyState(
              icon: Icons.event_available_outlined,
              title: l10n.homeAgendaEmptyTitle,
              message: l10n.homeAgendaEmptyBody,
            ),
          ),
        ],
      );
    }
    return SrRowGroup(
      title: l10n.homeAgendaTitle,
      onSeeAll: canViewTasks ? () => context.go(Routes.tasks) : null,
      rows: [for (final item in items) _AgendaRow(item: item)],
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final leadId = item.leadId;
    return SrListRow(
      title: item.title,
      subtitle: _subtitle(context),
      leading: SrAvatar(name: item.title),
      trailing: _tag(context),
      chevron: true,
      onTap: () => context.push(
        leadId == null ? Routes.taskFor(item.taskId) : Routes.leadFor(leadId),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final isBangla = fmt.isBangla;
    final dueAt = item.dueAt;
    final time = dueAt == null ? null : fmt.time(dueAt);
    final note = item.note;
    final parts = switch (item.kind) {
      AgendaKind.call => [l10n.homeAgendaCall, ?time, ?note],
      AgendaKind.visit => [
        l10n.homeAgendaVisit,
        ?time,
        ?item.area?.of(isBangla),
      ],
      AgendaKind.followUp => [
        l10n.homeAgendaFollowUp,
        if (item.daysSilent > 0)
          l10n.homeAgendaSilent(fmt.number(item.daysSilent))
        else
          ?time,
      ],
      AgendaKind.whatsApp => [
        l10n.homeAgendaWhatsApp,
        l10n.homeAgendaReplyPending,
      ],
      AgendaKind.meeting => [l10n.homeAgendaMeeting, ?time, ?note],
      AgendaKind.task => [l10n.homeAgendaTask, ?time, ?note],
    };
    return parts.join(' · ');
  }

  Widget? _tag(BuildContext context) {
    final l10n = context.l10n;
    if (item.isOverdue) return SrTag(l10n.homeTagOverdue, tone: SrTone.err);
    if (item.isNew) return SrTag(l10n.homeTagNew, tone: SrTone.ok);
    final stage = item.stage;
    if (stage == null) return null;
    return SrTag(stage.of(context.fmt.isBangla), tone: stageTone(item.stageId));
  }
}
