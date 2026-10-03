import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The lead's history, newest first, in the prototype's `.tl` style.
class LeadTimeline extends StatelessWidget {
  const LeadTimeline({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final entries = lead.timeline;
    if (entries.isEmpty) {
      return SrCard(
        child: Text(
          context.l10n.leadsTimelineEmpty,
          style: AppText.meta(c.ink2),
        ),
      );
    }
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        children: [
          for (final (i, entry) in entries.indexed)
            _Entry(lead: lead, entry: entry, last: i == entries.length - 1),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.lead, required this.entry, required this.last});

  final Lead lead;
  final LeadActivity entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final at = entry.occurredOn;
    final minutes = entry.durationMinutes;
    final amount = entry.amount;
    final photos = entry.photoCount;
    final duration = minutes == null
        ? null
        : l10n.leadsMinutes(fmt.number(minutes));
    final outcome = entry.outcome;

    final title = switch (entry.kind) {
      LeadActivityKind.call
          when outcome != null && outcome != CallOutcome.answered =>
        leadMeta([l10n.leadsKindCall, outcome.label(l10n)]),
      LeadActivityKind.call => leadMeta([l10n.leadsKindCall, duration]),
      LeadActivityKind.quotation => l10n.leadsTimelineQuotation(
        entry.reference ?? '',
      ),
      LeadActivityKind.stageChange => l10n.leadsMovedTo(
        entry.stageName?.of(fmt.isBangla) ?? '',
      ),
      LeadActivityKind.task => l10n.leadsTimelineTaskDone,
      final kind => kind.label(l10n),
    };
    final subtitle = switch (entry.kind) {
      LeadActivityKind.quotation => leadMeta([
        entry.channel,
        amount == null ? null : fmt.moneyCompact(amount),
        entry.viewed ? l10n.leadsViewed : null,
      ]),
      LeadActivityKind.created => lead.source?.name.of(fmt.isBangla),
      LeadActivityKind.task => entry.reference,
      LeadActivityKind.meeting ||
      LeadActivityKind.visit => leadMeta([entry.description, duration]),
      _ => entry.description,
    };
    final withPhotos = leadMeta([
      subtitle,
      photos > 0 ? l10n.leadsPhotoCount(fmt.number(photos)) : null,
    ]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SrTimelineItem(
        icon: entry.kind.icon,
        iconColor: entry.kind == LeadActivityKind.stageChange ? c.accent : null,
        title: title,
        time: at == null ? null : leadDayTime(context, at),
        subtitle: withPhotos.isEmpty ? null : withPhotos,
        last: last,
      ),
    );
  }
}
