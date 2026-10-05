import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/providers/scan_providers.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/scan_empty.dart';
import 'package:salesroot/features/tasks/view/widget/scan_limit_sheet.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/features/tasks/view/widget/toggle_row.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The product lines a scanned lead can be interested in, by their catalogue
/// category.
enum LeadInterest { solar, inverters, batteries, pumps, lighting, services }

extension on LeadInterest {
  String get wire => switch (this) {
    LeadInterest.solar => 'Solar',
    LeadInterest.inverters => 'Inverters',
    LeadInterest.batteries => 'Batteries',
    LeadInterest.pumps => 'Pumps',
    LeadInterest.lighting => 'Lighting',
    LeadInterest.services => 'Services',
  };

  String label(AppLocalizations l10n) => switch (this) {
    LeadInterest.solar => l10n.tasksInterestSolar,
    LeadInterest.inverters => l10n.tasksInterestInverters,
    LeadInterest.batteries => l10n.tasksInterestBatteries,
    LeadInterest.pumps => l10n.tasksInterestPumps,
    LeadInterest.lighting => l10n.tasksInterestLighting,
    LeadInterest.services => l10n.tasksInterestServices,
  };
}

/// #41 `scanlead`: the lead to make from the card. The leads feature owns
/// creating it, so this ends on the lead form, prefilled.
class ScanLeadScreen extends ConsumerWidget {
  const ScanLeadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final card = ref.watch(scanSessionProvider).value?.card;
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.tasksScanLeadTitle,
          subtitle: l10n.tasksScanLeadSub,
          actions: const [TasksLanguageToggle()],
        ),
        body: card == null ? const ScanEmpty() : _LeadForm(card: card),
      ),
    );
  }
}

class _LeadForm extends ConsumerStatefulWidget {
  const _LeadForm({required this.card});

  final ScannedCard card;

  @override
  ConsumerState<_LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends ConsumerState<_LeadForm> {
  late final _title = TextEditingController(
    text: widget.card.companyName.isEmpty
        ? widget.card.contactName
        : widget.card.companyName,
  );
  final _value = TextEditingController();
  LeadInterest _interest = LeadInterest.solar;
  bool _followUp = true;

  @override
  void dispose() {
    _title.dispose();
    _value.dispose();
    super.dispose();
  }

  DateTime get _followUpAt {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 10);
  }

  Future<void> _continue() async {
    final l10n = context.l10n;
    final card = widget.card;
    final who = card.contactName.isEmpty ? card.companyName : card.contactName;
    final canTask = ref.read(moduleAccessProvider(AppModule.task)).canAdd;
    if (_followUp && canTask) {
      final input = TaskInput(
        title: l10n.tasksAutoCall(who),
        type: TaskType.call,
        dueDate: _followUpAt,
        notes: [
          if (card.companyName.isNotEmpty) card.companyName,
          l10n.tasksSourceCard,
          if (card.phone.isNotEmpty) card.phone,
        ].join(' · '),
      );
      try {
        await showSrLoader(
          context,
          ref.read(taskEditorProvider.notifier).create(input),
        );
      } on ApiFailure catch (failure) {
        if (mounted) showSrError(context, failureText(context, failure));
        return;
      }
      if (!mounted) return;
      showSrSuccess(context, l10n.tasksFollowUpAdded);
    }
    if (!mounted) return;
    context.push(
      Uri(
        path: Routes.leadNew,
        queryParameters: {
          'name': ?_text(card.contactName),
          'phone': ?_text(card.phone),
          'email': ?_text(card.email),
          'company': ?_text(card.companyName),
          'designation': ?_text(card.designation),
          'source': visitingCardSource,
          'title': ?_text(_title.text),
          'value': ?_text(_value.text),
          'interest': _interest.wire,
        },
      ).toString(),
    );
  }

  static String? _text(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final card = widget.card;
    final canTask = ref.watch(moduleAccessProvider(AppModule.task)).canAdd;
    final followUp = _followUpAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              16,
              SrMetrics.gutter,
              24,
            ),
            children: [
              SrCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SrListRow(
                  title: card.contactName.isEmpty
                      ? card.companyName
                      : card.contactName,
                  subtitle: [
                    if (card.contactName.isNotEmpty) card.companyName,
                    card.designation,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  leading: SrAvatar(name: card.contactName),
                  trailing: SrTag(l10n.tasksScanLeadSub, tone: SrTone.ok),
                ),
              ),
              const SizedBox(height: 16),
              SrTextField(
                controller: _title,
                label: l10n.tasksLeadTitle,
                hint: l10n.tasksLeadTitleHint,
                prefixIcon: Icons.flag_outlined,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              SrFieldLabel(l10n.tasksInterest),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final interest in LeadInterest.values)
                    SrChip(
                      label: interest.label(l10n),
                      selected: interest == _interest,
                      onTap: () => setState(() => _interest = interest),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SrTextField(
                      controller: _value,
                      label: l10n.tasksDealValue,
                      optional: true,
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SrDropdownField(
                      label: l10n.tasksSource,
                      value: l10n.tasksSourceCard,
                      enabled: false,
                      onTap: null,
                    ),
                  ),
                ],
              ),
              if (canTask) ...[
                const SizedBox(height: 4),
                ToggleRow(
                  title: l10n.tasksNextFollowUp,
                  subtitle: l10n.tasksNextFollowUpSub(
                    '${l10n.commonTomorrow} ${fmt.time(followUp)}',
                  ),
                  value: _followUp,
                  onChanged: (on) => setState(() => _followUp = on),
                ),
              ],
            ],
          ),
        ),
        SrFooter(
          child: SrButton(
            label: l10n.tasksContinueLead,
            expand: true,
            onPressed: _continue,
          ),
        ),
      ],
    );
  }
}
