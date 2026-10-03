import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.trow`: a title with an optional line under it and a
/// switch on the right.
class FfToggleRow extends StatelessWidget {
  const FfToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.divider = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final subtitle = this.subtitle;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.line)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.rowTitle(c.ink)),
                if (subtitle != null)
                  Text(subtitle, style: AppText.meta(c.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SrSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
