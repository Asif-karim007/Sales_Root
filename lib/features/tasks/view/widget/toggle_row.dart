import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.trow`: a title, an optional line under it and a switch.
/// Tapping the line calls [onSubtitleTap], e.g. to pick a reminder time.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.onSubtitleTap,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final subtitle = this.subtitle;
    final onSubtitleTap = this.onSubtitleTap;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SrMetrics.rowMinHeight),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.rowTitle(c.ink)),
                if (subtitle != null)
                  GestureDetector(
                    onTap: onSubtitleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: AppText.meta(
                          onSubtitleTap == null ? c.ink2 : c.accent,
                        ),
                      ),
                    ),
                  ),
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
