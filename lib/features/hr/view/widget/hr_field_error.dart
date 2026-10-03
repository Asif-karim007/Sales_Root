import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// The error line [SrTextField] draws, for chip groups and field rows that
/// are not a single text field.
class HrFieldError extends StatelessWidget {
  const HrFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded, size: 14, color: c.danger),
          ),
          const SizedBox(width: 5),
          Expanded(child: Text(text, style: AppText.meta(c.danger, size: 12))),
        ],
      ),
    );
  }
}
