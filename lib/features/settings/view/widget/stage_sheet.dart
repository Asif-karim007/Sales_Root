import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
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
  late bool _showInEasy = widget.stage?.showInEasy ?? false;
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

  /// A new stage stands for the same universal step as the last open one.
  int get _universalStep =>
      widget.stage?.universalStep ??
      widget.pipeline.openStages.lastOrNull?.universalStep ??
      1;

  Future<void> _save() async {
    final input = StageInput(
      nameEn: _name.text,
      nameBn: _nameBn.text,
      winPercent: int.tryParse(_win.text.trim()) ?? 0,
      showInEasy: _showInEasy,
      universalStep: _universalStep,
      requiredFields: widget.stage?.requiredFields ?? const [],
    );
    final stage = widget.stage;
    final notifier = ref.read(pipelinesProvider.notifier);
    setState(() {
      _busy = true;
      _errors = const {};
    });
    try {
      await (stage == null
          ? notifier.addStage(widget.pipeline.id, input)
          : notifier.editStage(stage.id, input));
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: widget.stage == null
          ? l10n.settingsStageAdd
          : l10n.settingsStageEdit,
      subtitle: l10n.settingsStageNamesHint,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SrTextField(
              controller: _name,
              label: l10n.settingsStageNameEn,
              error: _errors['nameEn'],
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _nameBn,
              label: l10n.settingsStageNameBn,
              error: _errors['nameBn'],
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
                error: _errors['probability'],
              ),
              const SizedBox(height: 6),
              ToggleRow(
                title: l10n.settingsStageEasyToggle,
                value: _showInEasy,
                onChanged: (on) => setState(() => _showInEasy = on),
              ),
              if (_errors['showInEasy'] case final error?) ...[
                const SizedBox(height: 6),
                SrNote(message: error, tone: SrNoteTone.err),
              ],
            ],
            const SizedBox(height: 16),
            SrButton(
              label: l10n.commonSave,
              expand: true,
              loading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
