import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's "received" sheet: a big tick, [title], [message] and OK.
Future<void> showSupportDoneSheet(
  BuildContext context, {
  required String title,
  required String message,
}) => showSrSheet<void>(
  context: context,
  builder: (_) => SupportDoneSheet(title: title, message: message),
);

class SupportDoneSheet extends StatelessWidget {
  const SupportDoneSheet({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return SrSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Center(child: SupportBigCheck()),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.lead(c.ink2),
          ),
          const SizedBox(height: 20),
          SrButton(
            label: context.l10n.commonOk,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// The prototype's `.bigcheck`.
class SupportBigCheck extends StatelessWidget {
  const SupportBigCheck({super.key, this.icon = Icons.check_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
      child: Icon(icon, size: 34, color: c.accent),
    );
  }
}
