import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

/// One entry of the prototype's `.tl`: an icon disc on a vertical line, a
/// title with its time, and a muted line under it. Set [last] on the final
/// entry to end the line.
class SrTimelineItem extends StatelessWidget {
  const SrTimelineItem({
    super.key,
    required this.icon,
    required this.title,
    this.time,
    this.subtitle,
    this.child,
    this.iconColor,
    this.last = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? time;
  final String? subtitle;

  /// Extra content under [subtitle], like an attachment.
  final Widget? child;
  final Color? iconColor;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final time = this.time;
    final subtitle = this.subtitle;
    final child = this.child;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.avatarBg,
                      shape: BoxShape.circle,
                      border: SrBorder.all(color: c.line),
                    ),
                    child: Icon(icon, size: 14, color: iconColor ?? c.ink2),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 1,
                        constraints: const BoxConstraints(minHeight: 12),
                        color: c.line,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppText.rowTitle(c.ink, size: 14),
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 8),
                          Text(time, style: AppText.meta(c.ink3, size: 11.5)),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: AppText.meta(c.ink2)),
                    if (child != null) ...[const SizedBox(height: 6), child],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
