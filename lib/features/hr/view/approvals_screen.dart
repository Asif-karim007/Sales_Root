import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/approval.dart';
import 'package:salesroot/features/hr/providers/approvals_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_paged_list.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #153 `approvals`: the team's leave, expense and collection requests, with
/// approve, reject with a reason, and approve all.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  String? _busy;

  ApprovalActionsNotifier get _actions =>
      ref.read(approvalActionsProvider.notifier);

  Future<void> _approve(ApprovalItem item) {
    setState(() => _busy = item.id);
    return _actions.decide(ApprovalDecision(id: item.id, approve: true));
  }

  Future<void> _reject(ApprovalItem item) async {
    final reason = await showSrSheet<String>(
      context: context,
      builder: (_) => const _RejectSheet(),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = item.id);
    await _actions.decide(
      ApprovalDecision(id: item.id, approve: false, reason: reason),
    );
  }

  Future<void> _approveAll(List<ApprovalItem> items) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.hrApproveAllTitle,
      message: l10n.hrApproveAllBody(context.fmt.number(items.length)),
      confirmLabel: l10n.hrApproveAll(context.fmt.number(items.length)),
      icon: Icons.done_all_rounded,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = null);
    await _actions.approveAll(items);
  }

  void _onOutcome(AsyncValue<ApprovalOutcome?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(value: final ApprovalOutcome outcome):
        final waiting = outcome.item?.isPending ?? false;
        showSrSuccess(context, switch (outcome) {
          _ when waiting => l10n.hrApprovalSentToManager,
          ApprovalOutcome(approved: false) => l10n.hrRejectedOne,
          ApprovalOutcome(count: > 1) => l10n.hrApprovedMany(
            context.fmt.number(outcome.count),
          ),
          _ => l10n.hrApprovedOne,
        });
      case AsyncError(:final error):
        showHrFailure(context, error);
      default:
        return;
    }
    setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = ref.watch(approvalListProvider);
    final filter = ref.watch(approvalFilterProvider);
    final canApprove = ref
        .watch(moduleAccessProvider(AppModule.approvals))
        .canApprove;
    final working = ref.watch(approvalActionsProvider).isLoading;
    final counts = list.value?.facets[approvalCountsFacet] ?? const {};
    final pending = filter == ApprovalFilter.done
        ? const <ApprovalItem>[]
        : [
            for (final item in list.value?.items ?? const <ApprovalItem>[])
              if (item.isPending) item,
          ];

    ref.listen(approvalActionsProvider, (_, next) => _onOutcome(next));

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrApprovalsTitle,
        actions: const [HrLanguageToggle()],
        bottom: SrChipRow(
          padding: EdgeInsets.zero,
          chips: [
            for (final f in ApprovalFilter.values)
              SrChipItem(
                _filterLabel(l10n, f),
                count: f == ApprovalFilter.done ? null : counts[f.wire],
              ),
          ],
          index: ApprovalFilter.values.indexOf(filter),
          onChanged: (i) => ref
              .read(approvalFilterProvider.notifier)
              .set(ApprovalFilter.values[i]),
        ),
      ),
      body: SrAsyncView(
        value: list,
        onRetry: () => ref.invalidate(approvalListProvider),
        loading: (_) => const SrSkeletonList(cards: true, count: 4),
        isEmpty: (paged) => paged.isEmpty,
        empty: (_) => Center(
          child: SrEmptyState(
            icon: Icons.task_alt_rounded,
            title: filter == ApprovalFilter.done
                ? l10n.hrApprovalsDoneEmpty
                : l10n.hrApprovalsEmptyTitle,
            message: l10n.hrApprovalsEmptyBody,
          ),
        ),
        data: (context, paged) => HrPagedList<ApprovalItem>(
          paged: paged,
          onRefresh: () async {
            ref.invalidate(approvalListProvider);
            await ref.read(approvalListProvider.future);
          },
          itemBuilder: (context, item) => _ApprovalCard(
            item: item,
            canDecide: canApprove && item.isPending,
            busy: working && _busy == item.id,
            enabled: !working,
            onApprove: () => _approve(item),
            onReject: () => _reject(item),
          ),
        ),
      ),
      footer: canApprove && pending.length > 1
          ? SrButton(
              label: l10n.hrApproveAll(context.fmt.number(pending.length)),
              icon: Icons.done_all_rounded,
              expand: true,
              loading: working && _busy == null,
              onPressed: working ? null : () => _approveAll(pending),
            )
          : null,
    );
  }

  static String _filterLabel(AppLocalizations l10n, ApprovalFilter filter) =>
      switch (filter) {
        ApprovalFilter.pending => l10n.hrApprovalsPending,
        ApprovalFilter.leave => l10n.hrApprovalsLeave,
        ApprovalFilter.expense => l10n.hrApprovalsExpense,
        ApprovalFilter.collection => l10n.hrApprovalsCollection,
        ApprovalFilter.done => l10n.hrApprovalsDone,
      };
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.item,
    required this.canDecide,
    required this.busy,
    required this.enabled,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalItem item;
  final bool canDecide;
  final bool busy;
  final bool enabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final name = item.employeeName;

    return SrCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SrAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.approvalKind(item.kind)} · $name',
                      style: AppText.rowTitle(c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(approvalSummary(item), style: AppText.meta(c.ink2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              canDecide
                  ? SrTag(l10n.approvalTag(item.kind), tone: _kindTone)
                  : SrTag(
                      l10n.approvalState(item.state),
                      tone: item.state.tone,
                    ),
            ],
          ),
          if (canDecide) ...[
            const SizedBox(height: 10),
            _DecisionButtons(
              busy: busy,
              enabled: enabled,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ] else
            _Decided(item: item),
        ],
      ),
    );
  }

  SrTone get _kindTone => switch (item.kind) {
    ApprovalKind.leave => SrTone.accent,
    ApprovalKind.expense => SrTone.warn,
    ApprovalKind.collection => SrTone.ok,
    ApprovalKind.other => SrTone.info,
  };
}

/// The one-line description under the requester's name.
String approvalSummary(ApprovalItem item) {
  final reason = item.reason;
  return [
    if (item.summary.isNotEmpty) item.summary,
    if (reason != null && reason.isNotEmpty) reason,
  ].join(' · ');
}

class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons({
    required this.busy,
    required this.enabled,
    required this.onApprove,
    required this.onReject,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        SrButton(
          label: l10n.hrReject,
          icon: Icons.close_rounded,
          variant: SrButtonVariant.secondary,
          size: SrButtonSize.sm,
          onPressed: enabled ? onReject : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SrButton(
            label: l10n.hrApprove,
            icon: Icons.check_rounded,
            size: SrButtonSize.sm,
            expand: true,
            loading: busy,
            onPressed: enabled ? onApprove : null,
          ),
        ),
      ],
    );
  }
}

class _Decided extends StatelessWidget {
  const _Decided({required this.item});

  final ApprovalItem item;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final by = item.approverName;
    final note = item.decisionNote;
    final parts = [
      if (by != null) l10n.hrApprovalDecidedBy(by),
      if (note != null && note.isNotEmpty) note,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 48),
      child: Text(parts.join(' · '), style: AppText.meta(c.ink3, size: 12)),
    );
  }
}

/// Asks why; pops with the reason.
class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _reason = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.hrRejectTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrTextField(
              controller: _reason,
              label: l10n.hrRejectReason,
              hint: l10n.hrRejectReasonHint,
              multiline: true,
              autofocus: true,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              error: _showError ? l10n.hrRejectReasonError : null,
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l10n.hrReject,
              variant: SrButtonVariant.danger,
              expand: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
