import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// One `label … value` line of an [InfoLines] card.
class InfoLine {
  const InfoLine(this.label, this.value, {this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;
}

/// The prototype's card of `.line`s: a muted label on the left and the bold
/// value on the right; a tappable value is drawn in the accent colour.
class InfoLines extends StatelessWidget {
  const InfoLines({super.key, required this.lines});

  final List<InfoLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            _Line(line: lines[i]),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final InfoLine line;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final tappable = line.onTap != null;
    return InkWell(
      onTap: line.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.label, style: AppText.meta(c.ink2, size: 13.5)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                line.value,
                textAlign: TextAlign.end,
                style: AppText.rowTitle(
                  tappable ? c.accent : c.ink,
                  size: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
