import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/features/settings/view/widget/stage_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #89: each pipeline's stages, their order, names and win chance.
class PipelinesScreen extends ConsumerStatefulWidget {
  const PipelinesScreen({super.key});

  @override
  ConsumerState<PipelinesScreen> createState() => _PipelinesScreenState();
}

class _PipelinesScreenState extends ConsumerState<PipelinesScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pipelines = ref.watch(pipelinesProvider);
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.pipelines).select((a) => a.canEdit),
    );
    final list = pipelines.value ?? const <Pipeline>[];
    final selected = list.isEmpty
        ? null
        : list[_index.clamp(0, list.length - 1)];
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsPipelines,
        subtitle: canEdit ? null : l10n.settingsViewOnly,
        actions: [
          if (canEdit && selected != null)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.settingsStageAdd,
              onTap: () => showStageSheet(context, pipeline: selected),
            ),
          const LanguageAction(),
        ],
      ),
      body: SrAsyncView(
        value: pipelines,
        onRetry: () => ref.invalidate(pipelinesProvider),
        isEmpty: (list) => list.isEmpty,
        data: (context, list) => ListView(
          padding: screenPadding,
          children: [
            if (list.length > 1) ...[
              SrSegmented(
                segments: [for (final p in list) SrSegment(_name(context, p))],
                index: _index.clamp(0, list.length - 1),
                onChanged: (i) => setState(() => _index = i),
              ),
              const SizedBox(height: 14),
            ],
            if (selected != null)
              _PipelineStages(pipeline: selected, canEdit: canEdit),
            const SizedBox(height: 12),
            SrNote(
              icon: Icons.info_outline_rounded,
              message: canEdit
                  ? l10n.settingsPipelinesNote
                  : l10n.settingsPipelinesNoteViewOnly,
            ),
          ],
        ),
      ),
    );
  }

  String _name(BuildContext context, Pipeline pipeline) {
    return pipeline.isDefault
        ? context.l10n.settingsPipelineDefault(pipeline.name)
        : pipeline.name;
  }
}

class _PipelineStages extends ConsumerWidget {
  const _PipelineStages({required this.pipeline, required this.canEdit});

  final Pipeline pipeline;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = pipeline.openStages;
    final closing = pipeline.stages.where((s) => !s.isOpen).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrCard(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => _move(context, ref, from, to),
            children: [
              for (var i = 0; i < open.length; i++)
                _StageRow(
                  key: ValueKey(open[i].id),
                  stage: open[i],
                  index: i,
                  pipeline: pipeline,
                  canEdit: canEdit,
                  reorderable: canEdit,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SrRowGroup(
          rows: [
            for (final stage in closing)
              _StageRow(
                stage: stage,
                index: -1,
                pipeline: pipeline,
                canEdit: canEdit,
                reorderable: false,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    int from,
    int to,
  ) async {
    if (to == from) return;
    try {
      await ref
          .read(pipelinesProvider.notifier)
          .moveStage(pipeline.id, from, to);
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failure.message);
    }
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    super.key,
    required this.stage,
    required this.index,
    required this.pipeline,
    required this.canEdit,
    required this.reorderable,
  });

  final PipelineStage stage;

  /// Position among the open stages; -1 for won and lost.
  final int index;
  final Pipeline pipeline;
  final bool canEdit;
  final bool reorderable;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final color = switch (stage.kind) {
      StageKind.won => c.success,
      StageKind.lost => c.danger,
      StageKind.open => switch (index) {
        0 => c.ink3,
        1 => c.warning,
        _ => c.accent,
      },
    };
    return SrListRow(
      title: stage.name.of(fmt.isBangla),
      subtitle: stage.isOpen
          ? stage.showInEasy
                ? l10n.settingsStageEasy
                : l10n.settingsStageStandard
          : null,
      leading: Container(
        width: 10,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrRowTrailing(
            value: fmt.percent(stage.winPercent),
            meta: l10n.settingsStageProbability,
          ),
          if (reorderable)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.drag_indicator_rounded, color: c.ink3),
              ),
            ),
        ],
      ),
      onTap: canEdit
          ? () => showStageSheet(context, pipeline: pipeline, stage: stage)
          : null,
    );
  }
}
