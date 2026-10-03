import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/sr_card.dart';

/// The prototype's `.row`: leading, two lines of text and a trailing slot,
/// at least 60px tall.
class SrListRow extends StatelessWidget {
  const SrListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.chevron = false,
    this.divider = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool chevron;

  /// Draws a hairline under the row, inset by [padding].
  final bool divider;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final leading = this.leading;
    final trailing = this.trailing;
    final subtitle = this.subtitle;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SrMetrics.rowMinHeight),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.rowTitle(c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: AppText.meta(c.ink2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
            if (chevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.ink3),
            ],
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: divider
            ? DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: _InsetDivider(color: c.line, inset: padding),
                child: row,
              )
            : row,
      ),
    );
  }
}

class _InsetDivider extends Decoration {
  const _InsetDivider({required this.color, required this.inset});

  final Color color;
  final EdgeInsets inset;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _InsetDividerPainter(this);
}

class _InsetDividerPainter extends BoxPainter {
  _InsetDividerPainter(this._decoration);

  final _InsetDivider _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final y = offset.dy + size.height - 0.5;
    canvas.drawLine(
      Offset(offset.dx + _decoration.inset.left, y),
      Offset(offset.dx + size.width - _decoration.inset.right, y),
      Paint()
        ..color = _decoration.color
        ..strokeWidth = 1,
    );
  }
}

/// The prototype's `.rt`: a bold value over a muted line, right-aligned.
class SrRowTrailing extends StatelessWidget {
  const SrRowTrailing({super.key, this.value, this.meta, this.valueColor});

  final String? value;
  final String? meta;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final value = this.value;
    final meta = this.meta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          Text(value, style: AppText.rowTitle(valueColor ?? c.ink, size: 14)),
        if (value != null && meta != null) const SizedBox(height: 3),
        if (meta != null) Text(meta, style: AppText.meta(c.ink2, size: 12)),
      ],
    );
  }
}

/// The prototype's `.section`: a title with an optional link on the right.
class SrSectionHeader extends StatelessWidget {
  const SrSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final label = actionLabel;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppText.sectionTitle(c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (label != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  label,
                  style: AppText.style(
                    size: 13,
                    weight: FontWeight.w500,
                    color: c.ink2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A card of [rows] separated by hairlines, under an optional section header
/// whose "See all" link appears when [onSeeAll] is set.
class SrRowGroup extends StatelessWidget {
  const SrRowGroup({
    super.key,
    required this.rows,
    this.title,
    this.onSeeAll,
    this.seeAllLabel,
    this.dividerIndent = 16,
  });

  final List<Widget> rows;
  final String? title;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final title = this.title;

    final card = SrCard(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: c.line,
                  indent: dividerIndent,
                  endIndent: 16,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );

    if (title == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SrSectionHeader(
          title: title,
          actionLabel: onSeeAll == null
              ? null
              : seeAllLabel ?? context.l10n.commonSeeAll,
          onAction: onSeeAll,
        ),
        const SizedBox(height: 8),
        card,
      ],
    );
  }
}
