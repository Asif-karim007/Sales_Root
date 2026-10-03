import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// One label/value pair of an [InfoCard].
class InfoLine {
  const InfoLine(this.label, this.value, {this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;
}

/// The prototype's card of `.line` rows: label on the left, bold value on
/// the right.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.lines});

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
    final onTap = line.onTap;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(line.label, style: AppText.meta(c.ink2, size: 13.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                line.value,
                textAlign: TextAlign.end,
                style: AppText.rowTitle(c.ink, size: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: c.ink3),
            ],
          ],
        ),
      ),
    );
  }
}

/// The prototype's `.trow`: a title (up to two lines), an optional line
/// under it and a switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onChanged = this.onChanged;
    final subtitle = this.subtitle;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SrMetrics.rowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowTitle(c.ink),
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: AppText.meta(c.ink2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SrSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card of [SwitchRow]s separated by hairlines.
class SwitchCard extends StatelessWidget {
  const SwitchCard({
    super.key,
    required this.rows,
    this.tone = SrCardTone.plain,
  });

  final List<SwitchRow> rows;
  final SrCardTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      tone: tone,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            rows[i],
          ],
        ],
      ),
    );
  }
}
