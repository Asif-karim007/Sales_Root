import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/translations/translations.dart';
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
      leading: SrAvatar(name: item.who ?? item.title),
      trailing: item.isOverdue
          ? SrTag(context.l10n.homeTagOverdue, tone: SrTone.err)
          : null,
      chevron: true,
      onTap: () => context.push(
        leadId == null ? Routes.taskFor(item.id) : Routes.leadFor(leadId),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final dueAt = item.dueAt;
    final kind = switch (item.kind) {
      AgendaKind.call => l10n.homeAgendaCall,
      AgendaKind.visit => l10n.homeAgendaVisit,
      AgendaKind.followUp => l10n.homeAgendaFollowUp,
      AgendaKind.whatsApp => l10n.homeAgendaWhatsApp,
      AgendaKind.meeting => l10n.homeAgendaMeeting,
      AgendaKind.collect => l10n.homeAgendaCollect,
      AgendaKind.task => l10n.homeAgendaTask,
    };
    return [
      kind,
      if (dueAt != null) context.fmt.time(dueAt),
      ?item.who,
    ].join(' · ');
  }
}
