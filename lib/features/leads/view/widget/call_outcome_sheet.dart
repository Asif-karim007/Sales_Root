import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_dictation.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/lead_launcher.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Starts a call to [lead]'s contact and remembers it, so [LeadCallWatcher]
/// can ask how it went when the app comes back.
Future<void> callLead(BuildContext context, WidgetRef ref, Lead lead) async {
  final phone = lead.phone;
  final l10n = context.l10n;
  if (phone == null) {
    showSrWarning(context, l10n.leadsNoPhone);
    return;
  }
  final pending = ref.read(pendingCallProvider.notifier)
    ..start(
      PendingCall(
        leadId: lead.id,
        contactName: lead.contact?.name ?? lead.leadName,
        startedAt: DateTime.now(),
      ),
    );
  final opened = await LeadLauncher.call(phone);
  if (opened || !context.mounted) return;
  pending.take();
  showSrError(context, l10n.leadsLaunchFailed);
}

/// Asks for the outcome of a call started from a lead once the app is back
/// in front (#32).
class LeadCallWatcher extends ConsumerStatefulWidget {
  const LeadCallWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LeadCallWatcher> createState() => _LeadCallWatcherState();
}

class _LeadCallWatcherState extends ConsumerState<LeadCallWatcher> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    if (!mounted) return;
    final call = ref.read(pendingCallProvider.notifier).take();
    if (call == null) return;
    showSrSheet<void>(
      context: context,
      builder: (_) => CallOutcomeSheet(call: call),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// #32: how the call went, what was said and the next follow-up.
class CallOutcomeSheet extends ConsumerStatefulWidget {
  const CallOutcomeSheet({super.key, required this.call});

  final PendingCall call;

  @override
  ConsumerState<CallOutcomeSheet> createState() => _CallOutcomeSheetState();
}

class _CallOutcomeSheetState extends ConsumerState<CallOutcomeSheet> {
  static const _slot = 'call';

  final _note = TextEditingController();
  late final int _minutes = DateTime.now()
      .difference(widget.call.startedAt)
      .inMinutes;
  CallOutcome _outcome = CallOutcome.answered;
  late DateTime _next = _tomorrowAtTen();

  static DateTime _tomorrowAtTen() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 10);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _followsUp => _outcome != CallOutcome.wrongNumber;

  Future<void> _pickNext() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: _next,
      withTime: true,
      first: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _next = picked);
  }

  void _save() {
    ref
        .read(leadActivitySaveProvider(_slot).notifier)
        .log(
          widget.call.leadId,
          LeadActivityInput(
            kind: LeadActivityKind.call,
            occurredOn: widget.call.startedAt,
            durationMinutes: _minutes,
            outcome: _outcome,
            description: _note.text,
            followUpAt: _followsUp ? _next : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final saving = ref.watch(leadActivitySaveProvider(_slot)).isLoading;
    ref.listen(leadActivitySaveProvider(_slot), (_, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        showSrError(context, leadFailureText(l10n, next.error ?? ''));
        return;
      }
      if (next.value == null) return;
      showSrSuccess(context, l10n.leadsCallLogged);
      Navigator.of(context).pop();
    });
    final duration = _minutes < 1
        ? l10n.leadsUnderAMinute
        : l10n.leadsMinutes(fmt.number(_minutes));
    return SrSheet(
      title: leadMeta([l10n.leadsKindCall, duration, widget.call.contactName]),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OutcomeGrid(
              selected: _outcome,
              onPick: (outcome) => setState(() => _outcome = outcome),
            ),
            const SizedBox(height: 14),
            SrTextField(
              controller: _note,
              label: l10n.leadsWhatWasSaid,
              optional: true,
              hint: l10n.leadsWhatWasSaidHint,
              multiline: true,
              textCapitalization: TextCapitalization.sentences,
              suffix: LeadDictateButton(controller: _note),
            ),
            if (_followsUp)
              SrListRow(
                title: l10n.leadsNextFollowUp,
                subtitle: leadDayTime(context, _next),
                padding: const EdgeInsets.symmetric(vertical: 6),
                trailing: SrTag(l10n.leadsChange, tone: SrTone.accent),
                onTap: _pickNext,
              ),
            const SizedBox(height: 12),
            SrButton(
              label: l10n.commonSave,
              expand: true,
              loading: saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeGrid extends StatelessWidget {
  const _OutcomeGrid({required this.selected, required this.onPick});

  final CallOutcome selected;
  final ValueChanged<CallOutcome> onPick;

  @override
  Widget build(BuildContext context) {
    const values = CallOutcome.values;
    final rows = [
      for (var i = 0; i < values.length; i += 2)
        values.sublist(i, (i + 2).clamp(0, values.length)),
    ];
    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (final (j, outcome) in row.indexed) ...[
                if (j > 0) const SizedBox(width: 10),
                Expanded(
                  child: _OutcomeTile(
                    outcome: outcome,
                    selected: outcome == selected,
                    onTap: () => onPick(outcome),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    required this.outcome,
    required this.selected,
    required this.onTap,
  });

  final CallOutcome outcome;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Material(
      color: selected ? c.tint : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
        side: BorderSide(
          color: selected ? c.accent : c.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(outcome.icon, color: selected ? c.accent : c.ink2),
              const SizedBox(height: 6),
              Text(
                outcome.label(context.l10n),
                textAlign: TextAlign.center,
                style: AppText.rowTitle(c.ink, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
