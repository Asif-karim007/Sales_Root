import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

enum SrAvatarTone { neutral, accent, gold, danger, dark }

/// The prototype's `.av`: initials, an icon or a photo in a circle, or a
/// rounded square when [square].
class SrAvatar extends StatelessWidget {
  const SrAvatar({
    super.key,
    this.name,
    this.icon,
    this.imageUrl,
    this.size = 38,
    this.tone = SrAvatarTone.neutral,
    this.square = false,
  });

  final String? name;
  final IconData? icon;
  final String? imageUrl;
  final double size;
  final SrAvatarTone tone;
  final bool square;

  /// First letters of the first two words: `Karim Hossain` → `KH`.
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final (fill, ink) = switch (tone) {
      SrAvatarTone.neutral => (c.avatarBg, c.ink),
      SrAvatarTone.accent => (c.tint, c.accent),
      SrAvatarTone.gold => (c.goldTint, c.ink),
      SrAvatarTone.danger => (c.dangerTint, c.danger),
      SrAvatarTone.dark => (c.deep, c.onDeep),
    };
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final fallback = _fallback(ink);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: hasImage ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: fill,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square
            ? BorderRadius.circular(SrMetrics.radiusSmall)
            : null,
        border: tone == SrAvatarTone.dark ? null : SrBorder.all(color: c.line),
      ),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: pixels,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            )
          : fallback,
    );
  }

  Widget _fallback(Color ink) {
    final icon = this.icon;
    if (icon != null) return Icon(icon, size: size * 0.47, color: ink);
    return Text(
      initialsOf(name ?? ''),
      style: AppText.rowTitle(ink, size: size * 0.34),
      maxLines: 1,
    );
  }
}
