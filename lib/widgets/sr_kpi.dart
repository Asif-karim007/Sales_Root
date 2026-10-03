import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_card.dart';

/// The prototype's `.kpi` in a card: a label, a big value and an optional
/// delta line. [deltaUp] picks the arrow; [upIsGood] decides whether up is
/// green or red.
class SrKpiTile extends StatelessWidget {
  const SrKpiTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaUp,
    this.upIsGood = true,
    this.big = false,
    this.onTap,
    this.tone = SrCardTone.plain,
  });

  final String label;
  final String value;
  final String? delta;
  final bool? deltaUp;
  final bool upIsGood;
  final bool big;
  final VoidCallback? onTap;
  final SrCardTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final delta = this.delta;
    final up = deltaUp;
    final deltaColor = up == null
        ? c.ink2
        : up == upIsGood
        ? c.success
        : c.danger;

    return SrCard(
      tone: tone,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.label(c.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppText.metric(c.ink, size: big ? 30 : 24),
              maxLines: 1,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (up != null) ...[
                  Icon(
                    up
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 15,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    delta,
                    style: AppText.label(deltaColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Lays [tiles] out in rows of [columns] equal cells, each row as tall as its
/// tallest tile.
class SrStatGrid extends StatelessWidget {
  const SrStatGrid({
    super.key,
    required this.tiles,
    this.columns = 3,
    this.spacing = 10,
  });

  final List<Widget> tiles;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += columns) {
      if (start > 0) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < start + columns; i++) ...[
                if (i > start) SizedBox(width: spacing),
                Expanded(
                  child: i < tiles.length ? tiles[i] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
