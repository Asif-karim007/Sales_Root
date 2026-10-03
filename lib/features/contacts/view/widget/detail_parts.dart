import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The band under a detail screen's app bar: a big avatar, the name, one
/// muted line and tags.
class DetailHero extends StatelessWidget {
  const DetailHero({
    super.key,
    required this.name,
    required this.subtitle,
    this.tags = const [],
    this.company = false,
  });

  final String name;
  final String subtitle;
  final List<Widget> tags;

  /// Draws the dark square avatar companies use.
  final bool company;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Row(
          children: [
            SrAvatar(
              name: name,
              size: 56,
              square: company,
              tone: company ? SrAvatarTone.dark : SrAvatarTone.neutral,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.pageTitle(c.ink, size: 20)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppText.meta(c.ink2, size: 13)),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: tags),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One square of an [ActionTiles] grid.
class ActionTileData {
  const ActionTileData({
    required this.icon,
    required this.label,
    this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;

  /// Null greys the tile out.
  final VoidCallback? onTap;
  final String? count;
}

/// The prototype's row of `.tile`s: an icon over a short label.
class ActionTiles extends StatelessWidget {
  const ActionTiles({super.key, required this.tiles});

  final List<ActionTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [for (final tile in tiles) Expanded(child: _Tile(tile: tile))],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});

  final ActionTileData tile;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final count = tile.count;
    return Opacity(
      opacity: tile.onTap == null ? 0.45 : 1,
      child: SrCard(
        onTap: tile.onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Icon(tile.icon, size: 22, color: c.accent),
            const SizedBox(height: 5),
            Text(
              tile.label,
              style: AppText.label(c.ink, size: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (count != null)
              Text(count, style: AppText.meta(c.ink2, size: 11.5)),
          ],
        ),
      ),
    );
  }
}

/// One figure of a [KpiStrip].
class KpiCell {
  const KpiCell(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

/// The prototype's card of `.kpi`s side by side, split by hairlines.
class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.cells});

  final List<KpiCell> cells;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) ...[
                VerticalDivider(width: 1, thickness: 1, color: c.line),
                const SizedBox(width: 10),
              ],
              Expanded(child: _Kpi(cell: cells[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.cell});

  final KpiCell cell;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cell.label,
          style: AppText.label(c.ink2, size: 11.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            cell.value,
            style: AppText.metric(cell.color ?? c.ink, size: 15),
          ),
        ),
      ],
    );
  }
}

/// Muted text for a section with nothing in it.
class SectionEmpty extends StatelessWidget {
  const SectionEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(child: Text(text, style: AppText.meta(c.ink2, size: 13)));
  }
}
