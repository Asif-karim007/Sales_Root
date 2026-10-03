import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

/// The prototype's `.bub`: a message bubble, tinted and right-aligned when
/// [mine], with an optional [sender], [media] above the text and [time]
/// in the corner.
class SrChatBubble extends StatelessWidget {
  const SrChatBubble({
    super.key,
    required this.text,
    this.time,
    this.mine = false,
    this.sender,
    this.media,
    this.trailing,
    this.onLongPress,
  });

  final String text;
  final String? time;
  final bool mine;
  final String? sender;

  /// Usually an [SrBubbleMedia]; clipped to the bubble's inner radius.
  final Widget? media;

  /// Sits after [time], like a delivery tick.
  final Widget? trailing;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final time = this.time;
    final sender = this.sender;
    final media = this.media;
    final trailing = this.trailing;
    const big = Radius.circular(14);
    const small = Radius.circular(4);

    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: 0.78,
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Align(
          alignment: mine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mine ? c.tint : c.surface,
                border: mine ? null : SrBorder.all(color: c.line),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: big,
                  topEnd: big,
                  bottomStart: mine ? big : small,
                  bottomEnd: mine ? small : big,
                ),
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sender != null)
                      Text(sender, style: AppText.caption(c.accent, size: 12)),
                    if (media != null) ...[
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: media,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(text, style: AppText.body(c.ink, size: 14)),
                    if (time != null || trailing != null)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (time != null)
                              Text(
                                time,
                                style: AppText.meta(c.ink3, size: 10.5),
                              ),
                            if (trailing != null) ...[
                              const SizedBox(width: 4),
                              trailing,
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The prototype's `.bmedia`: a 90px grey slot with an icon, or [child]
/// (an image) filling it.
class SrBubbleMedia extends StatelessWidget {
  const SrBubbleMedia({
    super.key,
    this.icon = Icons.image_outlined,
    this.child,
    this.width = 220,
    this.height = 90,
    this.onTap,
  });

  final IconData icon;
  final Widget? child;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        color: c.avatarBg,
        alignment: Alignment.center,
        child: child ?? Icon(icon, size: 26, color: c.ink3),
      ),
    );
  }
}
