import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

enum SrButtonVariant { primary, secondary, ghost, danger, dark }

enum SrButtonSize { sm, md, lg }

class SrButton extends StatelessWidget {
  const SrButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SrButtonVariant.primary,
    this.size = SrButtonSize.md,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SrButtonVariant variant;
  final SrButtonSize size;
  final IconData? icon;
  final bool loading;

  /// Stretches to the full available width.
  final bool expand;

  double get _height => switch (size) {
    SrButtonSize.sm => SrMetrics.buttonHeightSmall,
    SrButtonSize.md => SrMetrics.buttonHeight,
    SrButtonSize.lg => SrMetrics.buttonHeightLarge,
  };

  double get _fontSize => switch (size) {
    SrButtonSize.sm => 13.5,
    SrButtonSize.md => 15,
    SrButtonSize.lg => 16,
  };

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final enabled = onPressed != null && !loading;
    final shape = BorderRadius.circular(SrMetrics.radiusButton);
    final ink = _ink(c);

    final decoration = switch (variant) {
      SrButtonVariant.primary => BoxDecoration(
        gradient: c.primaryGradient,
        borderRadius: shape,
      ),
      SrButtonVariant.secondary => BoxDecoration(
        color: c.surface,
        borderRadius: shape,
        border: SrBorder.all(color: c.line),
      ),
      SrButtonVariant.ghost => BoxDecoration(borderRadius: shape),
      SrButtonVariant.danger => BoxDecoration(
        color: c.dangerTint,
        borderRadius: shape,
      ),
      SrButtonVariant.dark => BoxDecoration(color: c.deep, borderRadius: shape),
    };

    final button = Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: _height,
          decoration: decoration,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: shape,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size == SrButtonSize.sm ? 14 : 18,
              ),
              child: Center(
                widthFactor: 1,
                child: loading ? _spinner(ink) : _content(ink),
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _ink(SrColors c) => switch (variant) {
    SrButtonVariant.primary => c.onAccent,
    SrButtonVariant.secondary || SrButtonVariant.ghost => c.accent,
    SrButtonVariant.danger => c.danger,
    SrButtonVariant.dark => c.onDeep,
  };

  Widget _spinner(Color ink) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2.2,
      valueColor: AlwaysStoppedAnimation<Color>(ink),
    ),
  );

  Widget _content(Color ink) {
    final icon = this.icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _fontSize + 3, color: ink),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: AppText.button(ink, size: _fontSize),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The prototype's `.ib`: a 40px bordered square, or 32px borderless when
/// [compact]. [onDark] suits it to a deep header.
class SrIconButton extends StatelessWidget {
  const SrIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.badge = false,
    this.badgeCount,
    this.compact = false,
    this.onDark = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool badge;
  final int? badgeCount;
  final bool compact;
  final bool onDark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final size = compact ? 32.0 : SrMetrics.iconButton;
    final shape = BorderRadius.circular(SrMetrics.radiusSmall);
    final fill = onDark
        ? c.onDeep.withValues(alpha: 0.12)
        : compact
        ? Colors.transparent
        : c.surface;

    Widget button = Material(
      color: Colors.transparent,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: shape,
          border: onDark || compact ? null : SrBorder.all(color: c.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Icon(
            icon,
            size: compact ? 19 : 20,
            color: color ?? (onDark ? c.onDeep : c.ink),
          ),
        ),
      ),
    );

    final count = badgeCount ?? 0;
    if (count > 0 || badge) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (count > 0)
            Positioned(top: -5, right: -6, child: _CountBadge(count: count))
          else
            Positioned(
              top: 8,
              right: 8,
              child: _BadgeDot(ring: onDark ? c.deep : c.surface),
            ),
        ],
      );
    }

    final tip = tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot({required this.ring});

  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: SrColors.of(context).danger,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: c.danger,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.surface, width: 1.5),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          context.fmt.digits(count > 99 ? '99+' : '$count'),
          style: AppText.caption(c.onAccent, size: 10),
        ),
      ),
    );
  }
}

/// The prototype's `.tog`.
class SrSwitch extends StatelessWidget {
  const SrSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onChanged = this.onChanged;

    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? c.accent : c.track,
            borderRadius: BorderRadius.circular(13),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: c.onDeep,
                shape: BoxShape.circle,
                boxShadow: c.cardShadow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SrCheckbox extends StatelessWidget {
  const SrCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onChanged = this.onChanged;

    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value ? c.accent : c.surface,
            borderRadius: BorderRadius.circular(6),
            border: SrBorder.all(color: value ? c.accent : c.ink3, width: 1.6),
          ),
          child: value
              ? Icon(Icons.check_rounded, size: 16, color: c.onAccent)
              : null,
        ),
      ),
    );
  }
}
