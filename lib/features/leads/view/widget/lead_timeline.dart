import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The lead's history, newest first, in the prototype's `.tl` style.
class LeadTimeline extends ConsumerWidget {
  const LeadTimeline({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final lookups = ref.watch(leadLookupsProvider).value;
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
            _Entry(
              entry: entry,
              lookups: lookups,
              last: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry, required this.last, this.lookups});

  final LeadActivity entry;
  final LeadLookups? lookups;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final at = entry.occurredOn;
    final minutes = entry.durationMinutes;
    final amount = entry.amount;
    final duration = minutes == null
        ? null
        : l10n.leadsMinutes(fmt.number(minutes));
    final outcome = entry.outcome;
    final description = entry.description;

    final title = switch (entry.kind) {
      LeadActivityKind.call
          when outcome != null && outcome != CallOutcome.answered =>
        leadMeta([l10n.leadsKindCall, outcome.label(l10n)]),
      LeadActivityKind.call => leadMeta([l10n.leadsKindCall, duration]),
      LeadActivityKind.stageChange => l10n.leadsMovedTo(
        entry.stageName?.of(fmt.isBangla) ?? '',
      ),
      LeadActivityKind.system when description != null => description,
      final kind => kind.label(l10n),
    };
    final subtitle = switch (entry.kind) {
      LeadActivityKind.won => amount == null ? null : fmt.moneyCompact(amount),
      LeadActivityKind.lost => leadMeta([
        lookups?.lostReason(entry.lostReason)?.name.of(fmt.isBangla),
        description,
      ]),
      LeadActivityKind.visit => leadMeta([description, duration]),
      LeadActivityKind.system => null,
      _ => description,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SrTimelineItem(
        icon: entry.kind.icon,
        iconColor: entry.kind == LeadActivityKind.stageChange ? c.accent : null,
        title: title,
        time: at == null ? null : leadDayTime(context, at),
        subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
        last: last,
      ),
    );
  }
}
