import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/ticket.dart';
import 'package:salesroot/features/hr/providers/ticket_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_line.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The ticket after it is raised: SLA, details, the thread and its status.
class TicketSummaryScreen extends ConsumerWidget {
  const TicketSummaryScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ticket = ref.watch(ticketProvider(ticketId));
    final actions = ticketActionsProvider(ticketId);
    final working = ref.watch(actions).isLoading;
    final canEdit = ref.watch(moduleAccessProvider(AppModule.support)).canEdit;
    final canVisit = ref.watch(moduleAccessProvider(AppModule.visit)).canAdd;
    final leadId = ticket.value?.leadId;

    ref.listen(actions, (_, next) {
      switch (next) {
        case AsyncData(value: final TicketAction action):
          showSrSuccess(
            context,
            action == TicketAction.reply
                ? l10n.hrTicketReplySent
                : l10n.hrTicketStatusChanged,
          );
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrTicketTitle,
        actions: const [HrLanguageToggle()],
      ),
      body: SrAsyncView(
        value: ticket,
        onRetry: () => ref.invalidate(ticketProvider(ticketId)),
        loading: (_) => const SrSkeletonList(count: 5),
        data: (context, value) => _SummaryBody(
          ticket: value,
          canEdit: canEdit && !working,
          onStatus: (status) => ref.read(actions.notifier).setStatus(status),
        ),
      ),
      footer: ticket.hasValue
          ? Row(
              children: [
                if (canVisit && leadId != null) ...[
                  Expanded(
                    child: SrButton(
                      label: l10n.hrTicketCreateVisit,
                      icon: Icons.directions_car_outlined,
                      variant: SrButtonVariant.secondary,
                      expand: true,
                      onPressed: () =>
                          context.push('${Routes.visits}?new=1&leadId=$leadId'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (canEdit)
                  Expanded(
                    child: SrButton(
                      label: l10n.hrTicketReply,
                      expand: true,
                      loading: working,
                      onPressed: () => _reply(context, ref),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Future<void> _reply(BuildContext context, WidgetRef ref) async {
    final text = await showSrSheet<String>(
      context: context,
      builder: (_) => const _ReplySheet(),
    );
    if (text == null) return;
    await ref.read(ticketActionsProvider(ticketId).notifier).reply(text);
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.ticket,
    required this.canEdit,
    required this.onStatus,
  });

  final Ticket ticket;
  final bool canEdit;
  final ValueChanged<TicketStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        _Header(ticket: ticket),
        const SizedBox(height: 12),
        HrLineCard(lines: _lines(context)),
        const SizedBox(height: 16),
        for (final message in ticket.messages) ...[
          _Message(message: message),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        SrFieldLabel(l10n.hrTicketChangeStatus),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in TicketStatus.values)
              SrChip(
                label: l10n.ticketStatus(status),
                selected: status == ticket.status,
                tone: status.tone,
                onTap: canEdit && status != ticket.status
                    ? () => onStatus(status)
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _lines(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final product = ticket.productName;
    final assignee = ticket.assigneeName;
    final opened = ticket.openedAt;
    return [
      if (product != null) HrLine(label: l10n.hrTicketItem, value: product),
      if (assignee != null)
        HrLine(
          label: l10n.hrTicketAssignee,
          value: l10n.hrTicketTechnician(
            assignee.of(fmt.isBangla).split(' ').first,
          ),
        ),
      if (opened != null)
        HrLine(
          label: l10n.hrTicketOpened,
          value: l10n.hrTicketOpenedVia(
            fmt.dayTime(opened),
            l10n.ticketSource(ticket.source),
          ),
        ),
      if (ticket.photos.isNotEmpty)
        HrLine(
          label: l10n.hrTicketPhotos,
          value: fmt.number(ticket.photos.length),
        ),
    ];
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final at = message.at;
    return SrChatBubble(
      text: message.text,
      mine: message.mine,
      sender: message.mine ? null : message.authorName,
      time: at == null ? null : context.fmt.time(at),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;

    return SrCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      onTap: () => context.push(Routes.customerFor(ticket.customerId)),
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.support_agent_rounded,
            tone: SrAvatarTone.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${ticket.code} · ${ticket.title}',
                  style: AppText.rowTitle(c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    ticket.customerName,
                    l10n.ticketIssue(ticket.issue),
                    l10n.ticketPriority(ticket.priority),
                    _sla(context),
                  ].join(' · '),
                  style: AppText.meta(c.ink2, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SrTag(l10n.ticketStatus(ticket.status), tone: ticket.status.tone),
        ],
      ),
    );
  }

  String _sla(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final sla = l10n.hrHours(fmt.number(ticket.priority.slaHours));
    final left = ticket.slaMinutesLeft;
    if (left == null) return l10n.hrTicketSla(sla);
    if (left < 0) return l10n.hrTicketSlaBreached(sla);
    return l10n.hrTicketSlaLeft(sla, fmt.hoursMinutes(left));
  }
}

/// Asks for the reply; pops with the text.
class _ReplySheet extends StatefulWidget {
  const _ReplySheet();

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.hrTicketReply,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrTextField(
              controller: _text,
              hint: l10n.hrTicketReplyHint,
              multiline: true,
              autofocus: true,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l10n.commonSend,
              icon: Icons.send_rounded,
              expand: true,
              onPressed: _text.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_text.text.trim()),
            ),
          ],
        ),
      ),
    );
  }
}
