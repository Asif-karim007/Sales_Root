import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/home/models/search_result.dart';
import 'package:salesroot/features/home/providers/search_providers.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// One search result; opening it saves the search to the recent list.
class SearchHitRow extends ConsumerWidget {
  const SearchHitRow({super.key, required this.hit});

  final SearchHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrListRow(
      title: hit.title,
      subtitle: _subtitle(context),
      leading: hit.kind == SearchKind.task
          ? const SrAvatar(
              icon: Icons.check_circle_outline_rounded,
              tone: SrAvatarTone.accent,
            )
          : SrAvatar(name: hit.title),
      trailing: _tag(context.l10n),
      chevron: true,
      onTap: () {
        ref
            .read(recentSearchesProvider.notifier)
            .remember(ref.read(searchQueryProvider).term);
        context.push(hit.route);
      },
    );
  }

  String? _subtitle(BuildContext context) {
    final fmt = context.fmt;
    final value = hit.value;
    final dueAt = hit.dueAt;
    return switch (hit.kind) {
      SearchKind.lead => [
        ?hit.stage?.of(fmt.isBangla),
        if (value != null) fmt.moneyCompact(value),
      ].join(' · '),
      SearchKind.task => [
        if (dueAt != null) fmt.dayTime(dueAt),
        ?hit.subtitle,
      ].join(' · '),
      SearchKind.contact || SearchKind.company => hit.subtitle,
    };
  }

  Widget _tag(AppLocalizations l10n) => switch (hit.kind) {
    SearchKind.lead => SrTag(l10n.homeTagLead, tone: SrTone.accent),
    SearchKind.contact => SrTag(l10n.homeTagContact),
    SearchKind.company => SrTag(l10n.homeTagCompany),
    SearchKind.task =>
      hit.isDone
          ? SrTag(l10n.homeTagDone, tone: SrTone.ok)
          : SrTag(l10n.homeTagTask),
  };
}
