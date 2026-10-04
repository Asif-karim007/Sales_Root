import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

class LostReasonChoice {
  const LostReasonChoice({required this.reasonId, this.note});

  final int reasonId;
  final String? note;
}

/// #31: why the lead was lost, picked before it moves to Lost.
class LostReasonSheet extends ConsumerStatefulWidget {
  const LostReasonSheet({super.key});

  @override
  ConsumerState<LostReasonSheet> createState() => _LostReasonSheetState();
}

class _LostReasonSheetState extends ConsumerState<LostReasonSheet> {
  final _note = TextEditingController();
  int? _reasonId;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final reasonId = _reasonId;
    if (reasonId == null) return;
    Navigator.of(
      context,
    ).pop(LostReasonChoice(reasonId: reasonId, note: _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.leadsLostTitle,
      child: SrAsyncView(
        value: ref.watch(leadLookupsProvider),
        loading: (_) => const SrSkeletonList(count: 5, shrinkWrap: true),
        onRetry: () => ref.invalidate(leadLookupsProvider),
        data: (context, lookups) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Reasons(
                reasons: lookups.lostReasons,
                selected: _reasonId,
                onPick: (id) => setState(() => _reasonId = id),
              ),
              const SizedBox(height: 14),
              SrTextField(
                controller: _note,
                label: l10n.leadsNote,
                optional: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SrButton(
                label: l10n.leadsMarkLost,
                variant: SrButtonVariant.danger,
                expand: true,
                onPressed: _reasonId == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reasons extends StatelessWidget {
  const _Reasons({
    required this.reasons,
    required this.selected,
    required this.onPick,
  });

  final List<LeadOption> reasons;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final bangla = context.fmt.isBangla;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (final (i, reason) in reasons.indexed)
            SrListRow(
              title: reason.name.of(bangla),
              divider: i < reasons.length - 1,
              padding: const EdgeInsets.symmetric(vertical: 4),
              trailing: reason.id == selected
                  ? Icon(Icons.check_rounded, color: c.accent)
                  : null,
              onTap: () => onPick(reason.id),
            ),
        ],
      ),
    );
  }
}
