import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/level_labels.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Adds a stage to [pipeline], or edits [stage].
Future<void> showStageSheet(
  BuildContext context, {
  required Pipeline pipeline,
  PipelineStage? stage,
}) => showSrSheet<void>(
  context: context,
  builder: (_) => _StageSheet(pipeline: pipeline, stage: stage),
);

class _StageSheet extends ConsumerStatefulWidget {
  const _StageSheet({required this.pipeline, this.stage});

  final Pipeline pipeline;
  final PipelineStage? stage;

  @override
  ConsumerState<_StageSheet> createState() => _StageSheetState();
}

class _StageSheetState extends ConsumerState<_StageSheet> {
  late final _name = TextEditingController(text: widget.stage?.name.en);
  late final _nameBn = TextEditingController(text: widget.stage?.name.bn);
  late final _win = TextEditingController(
    text: '${widget.stage?.winPercent ?? 50}',
  );
  late ExperienceLevel _level =
      widget.stage?.minLevel ?? ExperienceLevel.standard;
  late bool _needsQuotation = widget.stage?.requiresQuotation ?? false;
  Map<String, String> _errors = const {};
  bool _busy = false;

  bool get _open => widget.stage?.isOpen ?? true;

  @override
  void dispose() {
    _name.dispose();
    _nameBn.dispose();
    _win.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(PipelinesNotifier n) action) async {
    setState(() {
      _busy = true;
      _errors = const {};
    });
    try {
      await action(ref.read(pipelinesProvider.notifier));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = failure.fieldErrors;
      });
      if (failure.fieldErrors.isEmpty) showSrError(context, failure.message);
    }
  }

  Future<void> _save() {
    final input = StageInput(
      name: _name.text,
      nameBn: _nameBn.text,
      winPercent: int.tryParse(_win.text.trim()) ?? -1,
      minLevel: _level,
      requiresQuotation: _needsQuotation,
    );
    final stage = widget.stage;
    final pipelineId = widget.pipeline.id;
    return _run(
      (n) => stage == null
          ? n.addStage(pipelineId, input)
          : n.editStage(pipelineId, stage.id, input),
    );
  }

  Future<void> _delete(PipelineStage stage) async {
    final l10n = context.l10n;
    final ok = await showSrConfirm(
      context,
      title: l10n.settingsStageDeleteTitle(stage.name.of(context.fmt.isBangla)),
      message: l10n.settingsStageDeleteBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run((n) => n.deleteStage(widget.pipeline.id, stage.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stage = widget.stage;
    return SrSheet(
      title: stage == null ? l10n.settingsStageAdd : l10n.settingsStageEdit,
      subtitle: l10n.settingsStageNamesHint,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SrTextField(
              controller: _name,
              label: l10n.settingsStageNameEn,
              error: _errors['Name'],
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _nameBn,
              label: l10n.settingsStageNameBn,
              error: _errors['NameBn'],
            ),
            if (_open) ...[
              const SizedBox(height: 12),
              SrTextField(
                controller: _win,
                label: l10n.settingsStageWin,
                suffixText: '%',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                error: _errors['WinPercent'],
              ),
              const SizedBox(height: 14),
              SrFieldLabel(l10n.settingsStageShownFrom),
              const SizedBox(height: 6),
              SrSegmented(
                segments: [
                  for (final level in ExperienceLevel.values)
                    SrSegment(level.label(l10n)),
                ],
                index: _level.index,
                onChanged: (i) =>
                    setState(() => _level = ExperienceLevel.values[i]),
              ),
              if (_errors['MinLevel'] case final error?) ...[
                const SizedBox(height: 6),
                SrNote(message: error, tone: SrNoteTone.err),
              ],
              const SizedBox(height: 6),
              ToggleRow(
                title: l10n.settingsStageNeedsQuotationToggle,
                value: _needsQuotation,
                onChanged: (on) => setState(() => _needsQuotation = on),
              ),
            ],
            const SizedBox(height: 16),
            SrButton(
              label: l10n.commonSave,
              expand: true,
              loading: _busy,
              onPressed: _busy ? null : _save,
            ),
            if (stage != null && stage.isOpen) ...[
              const SizedBox(height: 8),
              SrButton(
                label: l10n.settingsStageDelete,
                expand: true,
                variant: SrButtonVariant.ghost,
                onPressed: _busy ? null : () => _delete(stage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
