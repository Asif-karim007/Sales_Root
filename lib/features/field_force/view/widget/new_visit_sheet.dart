import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Picks the customer to visit now; pops with it, or null when cancelled.
Future<VisitTarget?> showNewVisitSheet(
  BuildContext context, {
  String? leadId,
}) => showSrSheet<VisitTarget>(
  context: context,
  builder: (_) => NewVisitSheet(leadId: leadId),
);

class NewVisitSheet extends ConsumerStatefulWidget {
  const NewVisitSheet({super.key, this.leadId});

  /// Prefills the lead's customer, as `?new=1&leadId=` does.
  final String? leadId;

  @override
  ConsumerState<NewVisitSheet> createState() => _NewVisitSheetState();
}

class _NewVisitSheetState extends ConsumerState<NewVisitSheet> {
  VisitTarget? _target;
  bool _loadingTarget = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final leadId = widget.leadId;
    if (leadId != null) _loadTarget(leadId);
  }

  Future<void> _loadTarget(String leadId) async {
    setState(() => _loadingTarget = true);
    try {
      final target = await ref.read(visitRepositoryProvider).leadTarget(leadId);
      if (mounted) setState(() => _target = target);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loadingTarget = false);
    }
  }

  Future<void> _pick() async {
    final l10n = context.l10n;
    final repository = ref.read(visitRepositoryProvider);
    final picked = await showSrSheet<VisitTarget>(
      context: context,
      builder: (_) => SrSearchSheet<VisitTarget>(
        title: l10n.ffNewVisitPickCustomer,
        searchHint: l10n.ffNewVisitSearchHint,
        search: (term, page) async =>
            (await repository.targets(term, page)).items,
        labelOf: (target) => target.companyName,
        subtitleOf: (target) => target.area,
        isSelected: (target) => target.companyId == _target?.companyId,
        withAvatar: true,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _target = picked;
        _error = null;
      });
    }
  }

  void _start() {
    final target = _target;
    if (target == null) {
      setState(() => _error = context.l10n.ffNewVisitLeadRequired);
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final target = _target;

    return SrSheet(
      title: l10n.ffNewVisitTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrPickerField(
            label: l10n.ffNewVisitCustomer,
            icon: Icons.storefront_outlined,
            placeholder: _loadingTarget
                ? l10n.ffLoading
                : l10n.ffNewVisitPickCustomer,
            value: target == null
                ? null
                : [
                    target.companyName,
                    ?(target.leadTitle ?? target.area),
                  ].join(' · '),
            error: _error,
            onTap: _pick,
          ),
          const SizedBox(height: 18),
          SrButton(
            label: l10n.ffNewVisitCheckInNow,
            icon: Icons.login_rounded,
            size: easy ? SrButtonSize.lg : SrButtonSize.md,
            expand: true,
            onPressed: _loadingTarget ? null : _start,
          ),
        ],
      ),
    );
  }
}
