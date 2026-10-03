import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.tile`: an icon over a short label, outlined in accent
/// when [selected].
class SalesTile extends StatelessWidget {
  const SalesTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(SrMetrics.radiusCard);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? c.tint : c.surface,
          borderRadius: shape,
          border: selected
              ? SrBorder.all(color: c.accent, width: 2)
              : SrBorder.all(color: c.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: c.accent),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.caption(c.ink, size: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays [tiles] out as equal columns in one row.
class SalesTileRow extends StatelessWidget {
  const SalesTileRow({super.key, required this.tiles, this.spacing = 8});

  final List<Widget> tiles;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}
