import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_dictation.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #33: log a call, visit, note or message on a lead, optionally setting the
/// next follow-up. Pops with true once saved.
class LeadActivityScreen extends ConsumerStatefulWidget {
  const LeadActivityScreen({super.key, required this.id, this.kind});

  final String id;
  final LeadActivityKind? kind;

  @override
  ConsumerState<LeadActivityScreen> createState() => _LeadActivityScreenState();
}

class _LeadActivityScreenState extends ConsumerState<LeadActivityScreen> {
  static const _slot = 'activity';
  static const _durations = [5, 10, 15, 20, 30, 45, 60, 90, 120];
  final _note = TextEditingController();
  late LeadActivityKind _kind = widget.kind ?? LeadActivityKind.call;
  late String _leadId = widget.id;
  String? _leadName;
  DateTime _when = DateTime.now();
  int? _minutes;
  bool _followUp = true;
  DateTime _followUpAt = _tomorrowAtTen();
  String? _noteError;

  static DateTime _tomorrowAtTen() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 10);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickLead() async {
    final repository = ref.read(leadRepositoryProvider);
    final picked = await showSrSheet<Lead>(
      context: context,
      builder: (context) => SrSearchSheet<Lead>(
        title: context.l10n.leadsLead,
        searchHint: context.l10n.leadsSearchHint,
        search: (term, page) async => (await repository.list(
          LeadQuery(search: term, page: page, openOnly: false),
        )).items,
        labelOf: (l) => l.leadName,
        subtitleOf: (l) => l.company?.name,
        withAvatar: true,
        isSelected: (l) => l.id == _leadId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _leadId = picked.id;
      _leadName = picked.leadName;
    });
  }

  Future<void> _pickWhen() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: _when,
      withTime: true,
      last: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _when = picked);
  }

  Future<void> _pickDuration() async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.leadsDuration,
        options: _durations,
        labelOf: (m) => l10n.leadsMinutes(fmt.number(m)),
        isSelected: (m) => m == _minutes,
      ),
    );
    if (picked != null && mounted) setState(() => _minutes = picked);
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final picked = await showSrDatePicker(
      context: context,
      initial: _followUpAt.isAfter(now) ? _followUpAt : _tomorrowAtTen(),
      withTime: true,
      first: now,
    );
    if (picked != null && mounted) setState(() => _followUpAt = picked);
  }

  void _save() {
    final l10n = context.l10n;
    final text = _note.text.trim();
    setState(() {
      _noteError = _kind == LeadActivityKind.note && text.isEmpty
          ? l10n.leadsErrorWhatHappened
          : null;
    });
    if (_noteError != null) return;
    ref
        .read(leadActivitySaveProvider(_slot).notifier)
        .log(
          _leadId,
          LeadActivityInput(
            kind: _kind,
            occurredOn: _when,
            durationMinutes: _kind.timed ? _minutes : null,
            description: text,
            followUpAt: _followUp ? _followUpAt : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final locale = ref.watch(appLocaleProvider);
    final save = ref.watch(leadActivitySaveProvider(_slot));
    final leadName =
        _leadName ?? ref.watch(leadProvider(widget.id)).value?.leadName;
    final minutes = _minutes;
    final serverError = switch (save.error) {
      final ApiFailure f => f.fieldError('body'),
      _ => null,
    };
    ref.listen(leadActivitySaveProvider(_slot), (_, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        final error = next.error;
        if (error is ApiFailure && error.isValidation) return;
        showSrError(context, leadFailureText(l10n, error ?? ''));
        return;
      }
      if (next.value == null) return;
      showSrSuccess(context, l10n.leadsActivityLogged);
      context.pop(true);
    });
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.leadsLogActivity,
          actions: [
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: SrMetrics.gutter),
          children: [
            SrChipRow(
              chips: [
                for (final kind in LeadActivityKind.loggable)
                  SrChipItem(kind.label(l10n)),
              ],
              index: LeadActivityKind.loggable.indexOf(_kind),
              onChanged: (i) =>
                  setState(() => _kind = LeadActivityKind.loggable[i]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  SrDropdownField(
                    label: l10n.leadsLead,
                    value: leadName,
                    icon: Icons.person_outline_rounded,
                    onTap: _pickLead,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SrDropdownField(
                          label: l10n.leadsWhen,
                          value: leadDayTime(context, _when),
                          icon: Icons.event_outlined,
                          onTap: _pickWhen,
                        ),
                      ),
                      if (_kind.timed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: SrDropdownField(
                            label: l10n.leadsDuration,
                            value: minutes == null
                                ? null
                                : l10n.leadsMinutes(fmt.number(minutes)),
                            placeholder: l10n.leadsPickDuration,
                            icon: Icons.schedule_rounded,
                            onTap: _pickDuration,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  SrTextField(
                    controller: _note,
                    label: l10n.leadsWhatHappened,
                    optional: _kind != LeadActivityKind.note,
                    hint: l10n.leadsWhatHappenedHint,
                    error: _noteError ?? serverError,
                    multiline: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  LeadDictateButton(
                    controller: _note,
                    label: l10n.leadsVoiceNote,
                  ),
                  const SizedBox(height: 8),
                  SrListRow(
                    title: l10n.leadsSetFollowUp,
                    subtitle: _followUp
                        ? leadDayTime(context, _followUpAt)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    trailing: SrSwitch(
                      value: _followUp,
                      onChanged: (on) => setState(() => _followUp = on),
                    ),
                    onTap: _followUp ? _pickFollowUp : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        footer: SrButton(
          label: l10n.commonSave,
          expand: true,
          loading: save.isLoading,
          onPressed: _save,
        ),
      ),
    );
  }
}
