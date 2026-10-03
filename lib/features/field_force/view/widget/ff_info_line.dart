import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// The prototype's `.line`: a label on the left, its value in bold on the
/// right, and a hairline under every line but the [last].
class FfInfoLine extends StatelessWidget {
  const FfInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.last = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Text(label, style: AppText.body(c.ink2, size: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.rowTitle(valueColor ?? c.ink, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
