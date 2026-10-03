import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

enum SrNoteTone { tint, gold, err, neutral }

/// The prototype's `.note`: a tinted strip with an icon and a short message,
/// and an optional [action] at the end.
class SrNote extends StatelessWidget {
  const SrNote({
    super.key,
    required this.message,
    this.tone = SrNoteTone.tint,
    this.icon,
    this.title,
    this.action,
  });

  final String message;
  final SrNoteTone tone;

  /// Defaults to an icon that fits [tone].
  final IconData? icon;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final (fill, ink, accent, fallback) = switch (tone) {
      SrNoteTone.tint => (c.tint, c.ink, c.accent, Icons.info_outline_rounded),
      SrNoteTone.gold => (
        c.goldTint,
        c.ink,
        c.gold,
        Icons.lightbulb_outline_rounded,
      ),
      SrNoteTone.err => (
        c.dangerTint,
        c.danger,
        c.danger,
        Icons.error_outline_rounded,
      ),
      SrNoteTone.neutral => (
        c.avatarBg,
        c.ink2,
        c.ink2,
        Icons.info_outline_rounded,
      ),
    };
    final title = this.title;
    final action = this.action;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: title == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Icon(icon ?? fallback, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(title, style: AppText.rowTitle(ink, size: 13.5)),
                Text(message, style: AppText.meta(ink)),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}
