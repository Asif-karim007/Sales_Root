import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #138 Accept an inbox lead into the main list, then open the lead form
/// prefilled from it.
Future<void> showAcceptLeadSheet(BuildContext context, InboxLead lead) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => AcceptLeadSheet(lead: lead),
    );

class AcceptLeadSheet extends ConsumerStatefulWidget {
  const AcceptLeadSheet({super.key, required this.lead});

  final InboxLead lead;

  @override
  ConsumerState<AcceptLeadSheet> createState() => _AcceptLeadSheetState();
}

class _AcceptLeadSheetState extends ConsumerState<AcceptLeadSheet> {
  int? _assignTo;
  int? _stageId;
  late bool _linkExisting = widget.lead.duplicate != null;
  bool _followUp = true;

  InboxLead get _lead => widget.lead;

  @override
  void initState() {
    super.initState();
    _assignTo = _lead.assignedToId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submit = ref.watch(acceptLeadSubmitProvider(_lead.id));
    ref.listen(acceptLeadSubmitProvider(_lead.id), _onSubmit);
    final stages = ref.watch(leadStagesProvider).value ?? const <LeadStage>[];
    final stage =
        stages.where((s) => s.id == _stageId).firstOrNull ?? stages.firstOrNull;
    return SrSheet(
      title: l10n.growthInboxAccept,
      subtitle: _lead.name,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrDropdownField(
              label: l10n.growthAcceptAssignTo,
              value: _assigneeLabel(context),
              onTap: _pickAssignee,
            ),
            const SizedBox(height: 12),
            SrDropdownField(
              label: l10n.growthAcceptStage,
              value: stage?.name.of(context.fmt.isBangla),
              placeholder: l10n.growthAcceptStage,
              onTap: stages.isEmpty ? null : () => _pickStage(stages, stage),
            ),
            const SizedBox(height: 12),
            SrDropdownField(
              label: l10n.growthAcceptContact,
              value: _contactLabel(l10n),
              onTap: _lead.duplicate == null ? null : _pickContact,
            ),
            const SizedBox(height: 4),
            GrowthToggleRow(
              title: l10n.growthAcceptFollowUp,
              subtitle: l10n.growthAcceptFollowUpWhen,
              value: _followUp,
              onChanged: (value) => setState(() => _followUp = value),
            ),
            const SizedBox(height: 12),
            SrButton(
              label: l10n.growthAcceptConfirm,
              expand: true,
              loading: submit.isLoading,
              onPressed: () => ref
                  .read(acceptLeadSubmitProvider(_lead.id).notifier)
                  .submit(
                    AcceptInput(
                      assignToId: _assignTo,
                      stageId: stage?.id ?? 1,
                      contactId: _linkExisting ? _contactId : null,
                      followUp: _followUp,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  int? get _contactId {
    final duplicate = _lead.duplicate;
    if (duplicate == null || duplicate.kind != DuplicateKind.contact) {
      return null;
    }
    return duplicate.id;
  }

  void _onSubmit(AsyncValue<InboxLead?>? _, AsyncValue<InboxLead?> next) {
    if (next case AsyncError(:final error)) {
      showSrError(context, growthFailureText(context, error));
      return;
    }
    if (next.value == null) return;
    final router = GoRouter.of(context);
    final duplicate = _lead.duplicate;
    final company = _linkExisting
        ? duplicate?.companyName ?? _lead.company
        : _lead.company;
    final email = _lead.email;
    showSrSuccess(context, context.l10n.growthAcceptDone(_lead.name));
    Navigator.of(context).pop();
    router.pushReplacement(
      Uri(
        path: Routes.leadNew,
        queryParameters: {
          'name': _lead.name,
          'phone': _lead.phone,
          'email': ?email,
          'company': ?company,
          'source': _lead.source.wire,
        },
      ).toString(),
    );
  }

  String _assigneeLabel(BuildContext context) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final id = _assignTo;
    if (id != null) {
      final members = ref.watch(growthMembersProvider).value ?? const [];
      final member = members.where((m) => m.id == id).firstOrNull;
      return member?.nameOf(bangla) ??
          _lead.assignedTo?.of(bangla) ??
          l10n.growthAcceptMember;
    }
    final suggestion = ref.watch(inboxSuggestionProvider(_lead.id));
    return switch (suggestion) {
      AsyncData(:final value) => l10n.growthAcceptByRule(
        value.memberName?.of(bangla) ?? l10n.growthModeQueue,
      ),
      AsyncError() => l10n.growthAcceptByRuleShort,
      _ => l10n.growthAcceptChecking,
    };
  }

  String _contactLabel(AppLocalizations l10n) {
    final duplicate = _lead.duplicate;
    if (duplicate == null || !_linkExisting) return l10n.growthAcceptNewContact;
    return l10n.growthAcceptLinkTo(duplicate.companyName ?? duplicate.name);
  }

  Future<void> _pickAssignee() async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final members = await runGrowthAction(
      context,
      ref.read(growthMembersProvider.future),
    );
    if (members == null || !mounted) return;
    final byId = {for (final m in members) m.id: m};
    const byRule = 0;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.growthAcceptAssignTo,
        options: [byRule, ...byId.keys],
        labelOf: (id) =>
            byId[id]?.nameOf(fmt.isBangla) ?? l10n.growthAcceptByRuleShort,
        subtitleOf: (id) => switch (byId[id]) {
          null => l10n.growthAcceptByRuleHint,
          final m when m.onLeave => l10n.growthMemberOnLeave,
          final m => l10n.growthMemberLoad(fmt.number(m.openLeads)),
        },
        isSelected: (id) => id == (_assignTo ?? byRule),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _assignTo = picked == byRule ? null : picked);
  }

  Future<void> _pickStage(List<LeadStage> stages, LeadStage? current) async {
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<LeadStage>(
      context: context,
      builder: (_) => SrOptionSheet<LeadStage>(
        title: context.l10n.growthAcceptStage,
        options: stages,
        labelOf: (s) => s.name.of(bangla),
        isSelected: (s) => s.id == current?.id,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _stageId = picked.id);
  }

  Future<void> _pickContact() async {
    final l10n = context.l10n;
    final duplicate = _lead.duplicate;
    if (duplicate == null) return;
    final link = await showSrSheet<bool>(
      context: context,
      builder: (_) => SrOptionSheet<bool>(
        title: l10n.growthAcceptContact,
        options: const [true, false],
        labelOf: (linked) => linked
            ? l10n.growthAcceptLinkTo(duplicate.companyName ?? duplicate.name)
            : l10n.growthAcceptNewContact,
        isSelected: (linked) => linked == _linkExisting,
      ),
    );
    if (link == null || !mounted) return;
    setState(() => _linkExisting = link);
  }
}
