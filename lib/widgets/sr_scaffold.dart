import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_button.dart';
import 'package:salesroot/widgets/sr_scroll.dart';

/// A screen on the canvas: [appBar] on top, [body] in the middle, then a
/// sticky [footer] action bar and the [bottomBar] (the tab bar).
class SrScaffold extends StatelessWidget {
  const SrScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.footer,
    this.bottomBar,
    this.floatingAction,
    this.backgroundColor,
    this.safeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;

  /// Usually an [SrAppBar] or [SrHeader]; either one pads for the status bar.
  final Widget? appBar;

  /// Content of the prototype's `.foot`, wrapped in [SrFooter].
  final Widget? footer;
  final Widget? bottomBar;
  final Widget? floatingAction;
  final Color? backgroundColor;

  /// Keeps [body] clear of the status bar (when there is no [appBar]) and of
  /// the home indicator (when there is no [footer] or [bottomBar]).
  final bool safeArea;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final appBar = this.appBar;
    final footer = this.footer;

    Widget content = body;
    if (safeArea) {
      content = SafeArea(
        top: appBar == null,
        bottom: footer == null && bottomBar == null,
        child: content,
      );
    }

    return SrScrollScope(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlay(c, appBar),
        child: Scaffold(
          backgroundColor: backgroundColor ?? c.canvas,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          floatingActionButton: floatingAction,
          bottomNavigationBar: bottomBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?appBar,
              Expanded(child: content),
              if (footer != null) SrFooter(child: footer),
            ],
          ),
        ),
      ),
    );
  }

  SystemUiOverlayStyle _overlay(SrColors c, Widget? appBar) {
    final darkTop = c.isDark || (appBar is SrHeader && appBar.dark);
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: darkTop ? Brightness.light : Brightness.dark,
      statusBarBrightness: darkTop ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: c.canvas,
      systemNavigationBarIconBrightness: c.isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}

/// The prototype's `.appbar`: back button, title with an optional subtitle and
/// actions, on the surface with a bottom hairline.
class SrAppBar extends StatelessWidget {
  const SrAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  final String? title;
  final String? subtitle;

  /// Replaces [title] and [subtitle].
  final Widget? titleWidget;

  /// Replaces the back button.
  final Widget? leading;

  /// Shows the back button when the route can pop.
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Sits under the title row, inside the bar, like a search field or chips.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final top = MediaQuery.viewPaddingOf(context).top;
    final leading = this.leading ?? _back(context);
    final bottom = this.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (leading != null) ...[leading, const SizedBox(width: 8)],
                  if (leading == null) const SizedBox(width: 8),
                  Expanded(child: titleWidget ?? _title(c)),
                  for (final action in actions) ...[
                    const SizedBox(width: 6),
                    action,
                  ],
                ],
              ),
            ),
            if (bottom != null) ...[const SizedBox(height: 10), bottom],
          ],
        ),
      ),
    );
  }

  Widget? _back(BuildContext context) {
    final onBack = this.onBack;
    if (!showBack) return null;
    if (onBack == null && !Navigator.of(context).canPop()) return null;
    return SrIconButton(
      icon: Icons.arrow_back_rounded,
      tooltip: context.l10n.commonBack,
      onTap: onBack ?? () => Navigator.of(context).maybePop(),
    );
  }

  Widget _title(SrColors c) {
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title ?? '',
          style: AppText.pageTitle(c.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: AppText.meta(c.ink2, size: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// The prototype's `.hdr`: a taller header holding a column of [children]
/// (brand bar, greeting, chips…), on the surface or deep green when [dark].
class SrHeader extends StatelessWidget {
  const SrHeader({
    super.key,
    required this.children,
    this.dark = false,
    this.gap = 12,
  });

  final List<Widget> children;
  final bool dark;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final top = MediaQuery.viewPaddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? c.deep : c.surface,
        border: dark ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          top + 12,
          SrMetrics.gutter,
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// The prototype's `.foot`: a sticky action bar on the surface with a top
/// hairline. Give it a button with `expand`, or a [Row] of [Expanded]s.
class SrFooter extends StatelessWidget {
  const SrFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          12,
          SrMetrics.gutter,
          12 + bottom,
        ),
        child: child,
      ),
    );
  }
}
