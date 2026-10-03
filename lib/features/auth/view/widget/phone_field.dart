import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/models/bd_phone.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The `.fin` showing the number typed on the keypad after a fixed +880.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.digits,
    required this.focused,
    this.error,
    this.onTap,
  });

  final String digits;
  final bool focused;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final error = this.error;
    final border = error != null
        ? c.danger
        : focused
        ? c.accent
        : c.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: context.l10n.authPhoneLabel,
          value: digits,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(SrMetrics.radiusButton),
                border: SrBorder.all(color: border, width: focused ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Text(
                    fmt.digits(BdPhone.countryCode),
                    style: AppText.style(
                      size: 17,
                      weight: FontWeight.w600,
                      color: c.ink2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fmt.phone(
                        digits.isEmpty
                            ? context.l10n.authPhoneHint
                            : BdPhone.group(digits),
                      ),
                      style: AppText.style(
                        size: 20,
                        weight: FontWeight.w500,
                        color: digits.isEmpty ? c.ink3 : c.ink,
                        letterSpacing: 1,
                        tabular: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error, style: AppText.meta(c.danger)),
        ],
      ],
    );
  }
}
