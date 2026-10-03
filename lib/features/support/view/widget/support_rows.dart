import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A title, optional subtitle and a switch, like the prototype's `.trow`.
class SupportToggleRow extends StatelessWidget {
  const SupportToggleRow({
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
    final subtitle = this.subtitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.rowTitle(c.ink)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppText.meta(c.ink2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// One line of the prototype's `.checklist`: a tick and [text].
class SupportCheckLine extends StatelessWidget {
  const SupportCheckLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 18, color: c.accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.lead(c.ink))),
        ],
      ),
    );
  }
}

/// A picked file with a remove button.
class SupportAttachmentChip extends StatelessWidget {
  const SupportAttachmentChip({
    super.key,
    required this.name,
    required this.icon,
    required this.onRemove,
    required this.removeLabel,
  });

  final String name;
  final IconData icon;
  final VoidCallback onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: c.avatarBg,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.ink2),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              name,
              style: AppText.meta(c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SrIconButton(
            icon: Icons.close_rounded,
            compact: true,
            color: c.ink2,
            tooltip: removeLabel,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

/// The deep-green media slot used for videos and lesson covers.
class SupportMediaCover extends StatelessWidget {
  const SupportMediaCover({
    super.key,
    required this.icon,
    this.height = 150,
    this.progress,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final double height;

  /// Draws a gold progress line along the bottom, 0–1.
  final double? progress;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final progress = this.progress;

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: c.deep,
            borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, size: 48, color: c.onDeep)),
              if (progress != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: SrProgressBar(
                    value: progress,
                    color: c.gold,
                    height: 4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
