import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_border.dart';

/// The prototype's `.keypad`: 1–9, then [extraKey] (blank by default), 0 and
/// backspace. Digits are shown in the current locale's script.
class SrKeypad extends StatelessWidget {
  const SrKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.extraKey,
    this.enabled = true,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  /// Bottom-left key, such as fingerprint unlock.
  final Widget? extraKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;

    Widget digit(int n) => _Key(
      onTap: enabled ? () => onDigit(n) : null,
      child: Text(
        fmt.digits('$n'),
        style: AppText.style(size: 22, weight: FontWeight.w600, color: c.ink),
      ),
    );

    final rows = [
      [digit(1), digit(2), digit(3)],
      [digit(4), digit(5), digit(6)],
      [digit(7), digit(8), digit(9)],
      [
        extraKey ?? const SizedBox(height: 54),
        digit(0),
        Semantics(
          button: true,
          label: context.l10n.dsKeypadBackspace,
          child: _Key(
            onTap: enabled ? onBackspace : null,
            child: Icon(Icons.backspace_outlined, size: 22, color: c.ink),
          ),
        ),
      ],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var k = 0; k < 3; k++) ...[
                if (k > 0) const SizedBox(width: 8),
                Expanded(child: rows[r][k]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(SrMetrics.radiusButton);

    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 54,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: shape,
          border: SrBorder.all(color: c.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The prototype's `.otp`: one box per digit of [value]; filled boxes and the
/// next one get the accent border, or all turn red when [error].
class SrOtpBoxes extends StatelessWidget {
  const SrOtpBoxes({
    super.key,
    required this.value,
    this.length = 6,
    this.obscure = false,
    this.error = false,
  });

  final String value;
  final int length;
  final bool obscure;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;

    return Row(
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(SrMetrics.radiusButton),
                border: SrBorder.all(
                  color: error
                      ? c.danger
                      : i <= value.length
                      ? c.accent
                      : c.line,
                  width: i == value.length && !error ? 1.5 : 1,
                ),
              ),
              child: i >= value.length
                  ? null
                  : obscure
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.ink,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Text(
                      fmt.digits(value[i]),
                      style: AppText.style(
                        size: 20,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The prototype's `.pins`: [length] rings, the first [filled] solid.
class SrPinDots extends StatelessWidget {
  const SrPinDots({
    super.key,
    required this.filled,
    this.length = 4,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = error ? c.danger : c.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: i < filled ? ink : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: ink, width: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
