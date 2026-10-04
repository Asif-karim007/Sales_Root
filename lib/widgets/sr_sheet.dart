import 'dart:async';

import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_button.dart';
import 'package:salesroot/widgets/sr_chips.dart';

Future<T?> showSrSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: SrColors.of(context).scrim,
    elevation: 0,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// Holds the screen behind a spinner until [work] completes, for actions the
/// user has to wait on before moving on.
Future<T> showSrLoader<T>(BuildContext context, Future<T> work) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: SrColors.of(context).scrim,
      builder: (_) => const PopScope(canPop: false, child: _Loader()),
    ),
  );
  try {
    return await work;
  } finally {
    navigator.pop();
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Center(
      child: Semantics(
        label: context.l10n.dsLoading,
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation<Color>(c.accent),
          ),
        ),
      ),
    );
  }
}

/// The prototype's `.sheet`: grab handle, title row with a close button, and
/// [child] below, at most 90% of the screen tall.
class SrSheet extends StatelessWidget {
  const SrSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.showClose = true,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// Sits in the title row before the close button.
  final Widget? trailing;
  final bool showClose;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final title = this.title;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(SrMetrics.radiusSheet),
          ),
          boxShadow: c.sheetShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Grab(),
                if (title != null) ...[
                  _Header(
                    title: title,
                    subtitle: subtitle,
                    trailing: trailing,
                    showClose: showClose,
                  ),
                  const SizedBox(height: 12),
                ],
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grab extends StatelessWidget {
  const _Grab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: SrColors.of(context).line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.showClose,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final subtitle = this.subtitle;
    final trailing = this.trailing;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.pageTitle(c.ink, size: 17)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.meta(c.ink2, size: 12)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
        if (showClose) ...[
          const SizedBox(width: 4),
          SrIconButton(
            icon: Icons.close_rounded,
            compact: true,
            color: c.ink2,
            tooltip: context.l10n.commonClose,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ],
    );
  }
}

/// One reassurance row inside an [SrConfirmSheet].
@immutable
class SrSheetBullet {
  const SrSheetBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

/// A decision sheet: icon, title, message, optional bullets, a primary
/// action, an optional danger action and cancel.
class SrConfirmSheet extends StatelessWidget {
  const SrConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.dangerLabel,
    this.onDanger,
    this.cancelLabel,
    this.icon = Icons.help_outline_rounded,
    this.tone = SrTone.accent,
    this.destructive = false,
    this.bullets = const <SrSheetBullet>[],
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? dangerLabel;
  final VoidCallback? onDanger;
  final String? cancelLabel;
  final IconData icon;
  final SrTone tone;

  /// Paints the primary action as a danger button.
  final bool destructive;
  final List<SrSheetBullet> bullets;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = tone.foreground(c);
    final dangerLabel = this.dangerLabel;

    return SrSheet(
      showClose: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.background(c),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: ink),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppText.pageTitle(c.ink, size: 19)),
            const SizedBox(height: 6),
            Text(message, style: AppText.lead(c.ink2)),
            for (final bullet in bullets) ...[
              const SizedBox(height: 10),
              _BulletRow(bullet: bullet, color: ink),
            ],
            const SizedBox(height: 20),
            SrButton(
              label: primaryLabel,
              expand: true,
              variant: destructive
                  ? SrButtonVariant.danger
                  : SrButtonVariant.primary,
              onPressed: onPrimary,
            ),
            if (dangerLabel != null) ...[
              const SizedBox(height: 8),
              SrButton(
                label: dangerLabel,
                expand: true,
                variant: SrButtonVariant.danger,
                onPressed: onDanger,
              ),
            ],
            const SizedBox(height: 8),
            SrButton(
              label: cancelLabel ?? context.l10n.commonCancel,
              expand: true,
              variant: SrButtonVariant.secondary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.bullet, required this.color});

  final SrSheetBullet bullet;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(bullet.icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(bullet.text, style: AppText.lead(c.ink2))),
      ],
    );
  }
}

/// Asks a yes/no question in an [SrConfirmSheet]; true when confirmed.
Future<bool> showSrConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final confirmed = await showSrSheet<bool>(
    context: context,
    builder: (sheetContext) => SrConfirmSheet(
      title: title,
      message: message,
      primaryLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      tone: destructive ? SrTone.err : SrTone.accent,
      destructive: destructive,
      onPrimary: () => Navigator.of(sheetContext).pop(true),
    ),
  );
  return confirmed ?? false;
}
