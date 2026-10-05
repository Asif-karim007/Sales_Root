import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

const _amount = 'amount';

/// What [stage] requires that [lead] does not have yet: `amount` (always for
/// Won) or custom field keys.
List<String> stageFieldsMissing(Lead lead, LeadStage stage) => [
  for (final key in {...stage.requiredFields, if (stage.isWon) _amount})
    if (key == _amount
        ? lead.estimatedAmount == null
        : lead.customText(key) == null)
      key,
];

class StageFields {
  const StageFields({this.amount, this.custom = const {}});

  final double? amount;
  final Map<String, String> custom;
}

/// Asks for the fields [stage] needs before a lead moves in; pops with
/// [StageFields].
class StageFieldsSheet extends ConsumerStatefulWidget {
  const StageFieldsSheet({super.key, required this.stage, required this.keys});

  final LeadStage stage;
  final List<String> keys;

  @override
  ConsumerState<StageFieldsSheet> createState() => _StageFieldsSheetState();
}

class _StageFieldsSheetState extends ConsumerState<StageFieldsSheet> {
  late final _controllers = {
    for (final key in widget.keys) key: TextEditingController(),
  };
  final _errors = <String, String>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final values = {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    final amount = double.tryParse(values[_amount] ?? '');
    setState(() {
      _errors
        ..clear()
        ..addAll({
          for (final entry in values.entries)
            if (entry.value.isEmpty)
              entry.key: l10n.leadsErrorRequired
            else if (entry.key == _amount && amount == null)
              entry.key: l10n.leadsErrorAmount,
        });
    });
    if (_errors.isNotEmpty) return;
    Navigator.of(context).pop(
      StageFields(
        amount: amount,
        custom: {
          for (final entry in values.entries)
            if (entry.key != _amount) entry.key: entry.value,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final lookups = ref.watch(leadLookupsProvider).value;
    return SrSheet(
      title: l10n.leadsStageNeeds(widget.stage.name.of(bangla)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final MapEntry(:key, value: controller)
                in _controllers.entries) ...[
              _field(key, controller, lookups?.field(key), bangla),
              const SizedBox(height: 14),
            ],
            SrButton(
              label: l10n.leadsMoveStage,
              expand: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    String label,
    List<String> options,
    TextEditingController controller,
  ) async {
    final picked = await showSrSheet<String>(
      context: context,
      builder: (_) => SrOptionSheet<String>(
        title: label,
        options: options,
        labelOf: (o) => o,
        isSelected: (o) => o == controller.text,
      ),
    );
    if (picked != null && mounted) setState(() => controller.text = picked);
  }

  Widget _field(
    String key,
    TextEditingController controller,
    LeadField? field,
    bool bangla,
  ) {
    final numeric = key == _amount || field?.type == LeadFieldType.number;
    final options = field?.options ?? const <String>[];
    final label = field?.label.of(bangla) ?? key;
    if (field?.type == LeadFieldType.select && options.isNotEmpty) {
      return SrDropdownField(
        label: label,
        value: controller.text,
        error: _errors[key],
        onTap: () => _pick(label, options, controller),
      );
    }
    return SrTextField(
      controller: controller,
      label: key == _amount ? context.l10n.leadsDealValue : label,
      error: _errors[key],
      suffixText: key == _amount ? '৳' : null,
      keyboardType: numeric ? TextInputType.number : null,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
