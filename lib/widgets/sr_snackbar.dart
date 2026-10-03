import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/widgets/sr_border.dart';

enum SrSnackTone { success, error, warning, info }

/// An action in the snackbar's trailing slot.
@immutable
class SrSnackAction {
  const SrSnackAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Shows the app's only snackbar shape, replacing any snackbar on screen.
void showSrSnack(
  BuildContext context,
  String message, {
  String? title,
  SrSnackTone tone = SrSnackTone.info,
  Duration duration = const Duration(seconds: 3),
  SrSnackAction? action,
}) {
  logDebug('[snack ${title ?? tone.name}] $message');
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: _SrSnackCard(
          message: message,
          title: title,
          tone: tone,
          action: action,
          onAction: messenger.hideCurrentSnackBar,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
}

void showSrSuccess(BuildContext context, String message, {String? title}) =>
    showSrSnack(context, message, title: title, tone: SrSnackTone.success);

void showSrError(BuildContext context, String message, {String? title}) =>
    showSrSnack(context, message, title: title, tone: SrSnackTone.error);

void showSrWarning(BuildContext context, String message, {String? title}) =>
    showSrSnack(context, message, title: title, tone: SrSnackTone.warning);

void showSrInfo(BuildContext context, String message, {String? title}) =>
    showSrSnack(context, message, title: title, tone: SrSnackTone.info);

class _SrSnackCard extends StatelessWidget {
  const _SrSnackCard({
    required this.message,
    required this.tone,
    required this.onAction,
    this.title,
    this.action,
  });

  final String message;
  final SrSnackTone tone;
  final VoidCallback onAction;
  final String? title;
  final SrSnackAction? action;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final (ink, fill, icon) = switch (tone) {
      SrSnackTone.success => (c.success, c.successTint, Icons.check_rounded),
      SrSnackTone.error => (
        c.danger,
        c.dangerTint,
        Icons.error_outline_rounded,
      ),
      SrSnackTone.warning => (
        c.warning,
        c.warningTint,
        Icons.warning_amber_rounded,
      ),
      SrSnackTone.info => (c.info, c.infoTint, Icons.info_outline_rounded),
    };
    final heading = title?.trim();
    final action = this.action;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
        border: SrBorder.all(color: c.line),
        boxShadow: c.floatShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (heading != null && heading.isNotEmpty)
                  Text(
                    heading,
                    style: AppText.rowTitle(c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  message,
                  style: AppText.meta(
                    heading == null || heading.isEmpty ? c.ink : c.ink2,
                    size: 13.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                onAction();
                action.onPressed();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(action.label, style: AppText.button(c.accent)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
