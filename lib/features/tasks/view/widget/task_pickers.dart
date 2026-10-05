import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Searches the leads page by page; pops with the chosen one.
Future<LeadOption?> pickLead(
  BuildContext context,
  WidgetRef ref, {
  String? currentId,
}) {
  final l10n = context.l10n;
  final repository = ref.read(taskLookupRepositoryProvider);
  return showSrSheet<LeadOption>(
    context: context,
    builder: (_) => SrSearchSheet<LeadOption>(
      title: l10n.tasksFieldLinked,
      searchHint: l10n.tasksLeadSearch,
      withAvatar: true,
      search: (term, page) async =>
          (await repository.searchLeads(term, page)).items,
      labelOf: (lead) => lead.title,
      subtitleOf: (lead) => [
        if (lead.companyName != lead.title) ?lead.companyName,
        ?lead.contactName,
      ].join(' · '),
      isSelected: (lead) => lead.id == currentId,
    ),
  );
}

/// The teammates a task can go to; pops with the chosen one.
Future<MemberOption?> pickMember(
  BuildContext context,
  List<MemberOption> members, {
  required String title,
  String? currentId,
}) {
  final l10n = context.l10n;
  final bangla = context.fmt.isBangla;
  return showSrSheet<MemberOption>(
    context: context,
    builder: (_) => SrOptionSheet<MemberOption>(
      title: title,
      options: members,
      withAvatar: true,
      labelOf: (m) =>
          m.isMe ? l10n.tasksMemberMe(m.name.of(bangla)) : m.name.of(bangla),
      subtitleOf: (m) => m.designation,
      isSelected: (m) => m.id == currentId,
    ),
  );
}
