import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.line`: a label on the left, a bold value on the right.
class HrLine extends StatelessWidget {
  const HrLine({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.small = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool small;

  static const double _valueShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final size = small ? 12.5 : 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: AppText.body(c.ink2, size: size)),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * _valueShare,
              ),
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppText.rowTitle(valueColor ?? c.ink, size: size),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card of [HrLine]s with hairlines between them.
class HrLineCard extends StatelessWidget {
  const HrLineCard({super.key, required this.lines});

  final List<Widget> lines;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            lines[i],
          ],
        ],
      ),
    );
  }
}
