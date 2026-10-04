import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/view/widget/voice_button.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// What the new-visit sheet decided: the planned visit, and whether to check
/// in right away.
typedef NewVisitResult = ({Visit visit, bool checkInNow});

Future<NewVisitResult?> showNewVisitSheet(
  BuildContext context, {
  int? leadId,
}) => showSrSheet<NewVisitResult>(
  context: context,
  builder: (_) => NewVisitSheet(leadId: leadId),
);

/// Plans a visit to a lead, or starts one now. Easy level only picks the
/// lead.
class NewVisitSheet extends ConsumerStatefulWidget {
  const NewVisitSheet({super.key, this.leadId});

  /// Prefills the lead, as `?new=1&leadId=` does.
  final int? leadId;

  @override
  ConsumerState<NewVisitSheet> createState() => _NewVisitSheetState();
}

class _NewVisitSheetState extends ConsumerState<NewVisitSheet> {
  final _purpose = TextEditingController();
  VisitTarget? _target;
  late DateTime _when = _nextHalfHour();
  bool _saving = false;
  bool _loadingTarget = false;
  String? _leadError;

  @override
  void initState() {
    super.initState();
    final leadId = widget.leadId;
    if (leadId != null) _loadTarget(leadId);
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  static DateTime _nextHalfHour() {
    final now = DateTime.now();
    final minutes = (now.hour * 60 + now.minute) ~/ 30 * 30 + 60;
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: minutes));
  }

  Future<void> _loadTarget(int leadId) async {
    setState(() => _loadingTarget = true);
    try {
      final target = await ref.read(visitRepositoryProvider).target(leadId);
      if (mounted) setState(() => _target = target);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _leadError = failure.message);
    } finally {
      if (mounted) setState(() => _loadingTarget = false);
    }
  }

  Future<void> _pickLead() async {
    final l10n = context.l10n;
    final repository = ref.read(visitRepositoryProvider);
    final picked = await showSrSheet<VisitTarget>(
      context: context,
      builder: (_) => SrSearchSheet<VisitTarget>(
        title: l10n.ffNewVisitPickLead,
        searchHint: l10n.ffNewVisitSearchHint,
        search: (term, page) async =>
            (await repository.targets(term, page)).items,
        labelOf: (target) => target.companyName,
        subtitleOf: (target) => target.leadTitle == target.companyName
            ? target.area?.of(context.fmt.isBangla)
            : target.leadTitle,
        isSelected: (target) => target.leadId == _target?.leadId,
        withAvatar: true,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _target = picked;
        _leadError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: _when,
      withTime: true,
      first: DateTime.now().subtract(const Duration(days: 1)),
    );
    if (picked != null && mounted) setState(() => _when = picked);
  }

  Future<void> _save({required bool now}) async {
    final l10n = context.l10n;
    final target = _target;
    if (target == null) {
      setState(() => _leadError = l10n.ffNewVisitLeadRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final visit = await ref
          .read(visitsProvider.notifier)
          .create(
            VisitInput(
              leadId: target.leadId,
              plannedAt: now ? DateTime.now() : _when,
              purpose: _purpose.text,
            ),
          );
      if (mounted) Navigator.of(context).pop((visit: visit, checkInNow: now));
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _leadError = failure.fieldError('LeadId');
      });
      if (failure.fieldErrors.isEmpty) showSrError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final target = _target;

    return SrSheet(
      title: l10n.ffNewVisitTitle,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrPickerField(
              label: l10n.ffNewVisitLead,
              icon: Icons.storefront_outlined,
              placeholder: _loadingTarget
                  ? l10n.ffLoading
                  : l10n.ffNewVisitPickLead,
              value: target == null
                  ? null
                  : [
                      target.companyName,
                      ?target.area?.of(context.fmt.isBangla),
                    ].join(' · '),
              error: _leadError,
              onTap: _pickLead,
            ),
            if (!easy) ...[
              const SizedBox(height: 12),
              SrPickerField(
                label: l10n.ffNewVisitWhen,
                icon: Icons.schedule_rounded,
                value: context.fmt.dayTime(_when),
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),
              SrTextField(
                controller: _purpose,
                label: l10n.ffNewVisitPurpose,
                optional: true,
                hint: l10n.ffNewVisitPurposeHint,
                suffix: FfVoiceButton(controller: _purpose),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            const SizedBox(height: 18),
            SrButton(
              label: l10n.ffNewVisitCheckInNow,
              icon: Icons.login_rounded,
              size: easy ? SrButtonSize.lg : SrButtonSize.md,
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : () => _save(now: true),
            ),
            if (!easy) ...[
              const SizedBox(height: 8),
              SrButton(
                label: l10n.ffNewVisitPlan,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: _saving ? null : () => _save(now: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
