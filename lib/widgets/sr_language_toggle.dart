import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/sr_border.dart';

/// The prototype's `.langpill`: বাং / EN with the current one filled. A tap
/// anywhere switches; the caller owns the locale.
class SrLanguageToggle extends StatelessWidget {
  const SrLanguageToggle({
    super.key,
    required this.isBangla,
    required this.onChanged,
    this.onDark = false,
  });

  final bool isBangla;

  /// Called with true to switch to Bangla, false for English.
  final ValueChanged<bool> onChanged;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: isBangla ? l10n.languageEnglish : l10n.languageBangla,
      child: GestureDetector(
        onTap: () => onChanged(!isBangla),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: onDark ? c.onDeep.withValues(alpha: 0.12) : c.canvas,
            borderRadius: BorderRadius.circular(999),
            border: onDark ? null : SrBorder.all(color: c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Option(
                label: l10n.dsLangShortBangla,
                active: isBangla,
                onDark: onDark,
              ),
              _Option(
                label: l10n.dsLangShortEnglish,
                active: !isBangla,
                onDark: onDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.active,
    required this.onDark,
  });

  final String label;
  final bool active;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = active
        ? c.onAccent
        : onDark
        ? c.onDeepMuted
        : c.ink2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.style(size: 11.5, weight: FontWeight.w700, color: ink),
      ),
    );
  }
}
