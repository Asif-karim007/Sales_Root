import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/sr_border.dart';
import 'package:salesroot/widgets/sr_chips.dart';

/// One destination in an [SrTabBar].
class SrTabItem {
  const SrTabItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;

  /// A count bubble on the icon; 0 shows a dot.
  final int? badge;
}

/// The prototype's floating `.nav`: a surface card on a five-column grid, the
/// [SrFab] in the centre column when [onAdd] is set.
class SrTabBar extends StatelessWidget {
  const SrTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.onAdd,
  });

  final List<SrTabItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onAdd = this.onAdd;
    final middle = items.length ~/ 2;
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    final buttonNav =
        defaultTargetPlatform == TargetPlatform.android &&
        MediaQuery.systemGestureInsetsOf(context).left == 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12 + (buttonNav ? navInset : navInset * 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(SrMetrics.radiusNav),
          border: SrBorder.all(color: c.line),
          boxShadow: c.floatShadow,
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i == middle && onAdd != null)
                Expanded(
                  child: Center(
                    heightFactor: 1,
                    child: SrFab(onTap: onAdd, tooltip: context.l10n.navAdd),
                  ),
                ),
              Expanded(
                child: _Item(
                  item: items[i],
                  active: index == i,
                  onTap: () => onChanged(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.active, required this.onTap});

  final SrTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = active ? c.accent : c.ink3;
    final badge = item.badge;

    Widget icon = Icon(
      active ? item.activeIcon ?? item.icon : item.icon,
      size: 22,
      color: ink,
    );
    if (badge != null) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            top: badge == 0 ? 0 : -6,
            right: badge == 0 ? 0 : -10,
            child: SrBadge(count: badge == 0 ? null : badge),
          ),
        ],
      );
    }

    return Semantics(
      selected: active,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? c.tint : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              icon,
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppText.caption(ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prototype's `.fab`: a 52px gradient square with a plus.
class SrFab extends StatelessWidget {
  const SrFab({
    super.key,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.size = 52,
    this.tooltip,
  });

  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(18);

    final fab = Material(
      color: Colors.transparent,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: c.primaryGradient,
          borderRadius: shape,
          boxShadow: c.floatShadow,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Icon(icon, size: 28, color: c.onAccent),
        ),
      ),
    );

    final tip = tooltip;
    return tip == null ? fab : Tooltip(message: tip, child: fab);
  }
}
