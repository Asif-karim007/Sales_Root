import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A centred count in its status colour over a label: Present, Late, Leave,
/// Absent.
class FfCountTile extends StatelessWidget {
  const FfCountTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        children: [
          Text(value, style: AppText.metric(color, size: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.label(c.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Four [FfCountTile]s in a row.
class FfCountRow extends StatelessWidget {
  const FfCountRow({super.key, required this.tiles});

  final List<FfCountTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}
