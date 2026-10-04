import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Lead counts per pipeline stage as bars against the fullest stage. The
/// header link opens the board.
class PipelineCard extends StatelessWidget {
  const PipelineCard({
    super.key,
    required this.stages,
    required this.scopeLabel,
    this.canOpen = true,
  });

  final List<StageCount> stages;
  final String scopeLabel;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final max = stages.fold<int>(0, (m, s) => s.count > m ? s.count : m);
    return SrCard(
      onTap: canOpen ? () => context.push(Routes.leadBoard) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(
            title: context.l10n.homePipeline,
            actionLabel: scopeLabel,
          ),
          for (final stage in stages) ...[
            const SizedBox(height: 10),
            SrBarRow(
              label: stage.name.of(fmt.isBangla),
              value: stage.count.toDouble(),
              max: max.toDouble(),
              valueLabel: fmt.number(stage.count),
            ),
          ],
        ],
      ),
    );
  }
}
