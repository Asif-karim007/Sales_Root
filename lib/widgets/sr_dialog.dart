import 'dart:async';

import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/sr_button.dart';
import 'package:salesroot/widgets/sr_card.dart';
import 'package:salesroot/widgets/sr_chips.dart';

/// A centred card with one action. [detail] sits between the title and the
/// message.
class SrAlertDialog extends StatelessWidget {
  const SrAlertDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.tone = SrTone.warn,
    this.actionIcon,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final SrTone tone;
  final IconData? actionIcon;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final detail = this.detail;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SrCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.background(c),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: tone.foreground(c)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.pageTitle(c.ink, size: 18),
              ),
              if (detail != null) ...[const SizedBox(height: 8), detail],
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.lead(c.ink2),
              ),
              const SizedBox(height: 20),
              SrButton(
                label: actionLabel,
                icon: actionIcon,
                expand: true,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Success confirmation with one action; the button closes the dialog and
/// then runs [onConfirm].
Future<void> showSrSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: SrColors.of(context).scrim,
    builder: (dialogContext) => SrAlertDialog(
      icon: Icons.check_rounded,
      tone: SrTone.ok,
      title: title,
      message: message,
      actionLabel: actionLabel ?? dialogContext.l10n.commonOk,
      onAction: () {
        Navigator.of(dialogContext).pop();
        onConfirm?.call();
      },
    ),
  );
}

/// Tells the user the server did not answer, and offers [onRetry].
Future<void> showSrNoResponseDialog({
  required BuildContext context,
  required Future<void> Function() onRetry,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: SrColors.of(context).scrim,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return SrAlertDialog(
        icon: Icons.cloud_off_rounded,
        tone: SrTone.err,
        title: l10n.dsNoResponseTitle,
        message: l10n.dsNoResponseBody,
        actionLabel: l10n.commonRetry,
        actionIcon: Icons.refresh_rounded,
        onAction: () {
          Navigator.of(dialogContext).pop();
          unawaited(onRetry());
        },
      );
    },
  );
}
