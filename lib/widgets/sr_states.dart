import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/sr_button.dart';
import 'package:salesroot/widgets/sr_card.dart';
import 'package:salesroot/widgets/sr_failure.dart';

/// Icon disc, title, message and an optional action, centred.
class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.fill,
    required this.ink,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final Color fill;
  final Color ink;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final message = this.message;
    final actionLabel = this.actionLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: ink),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.sectionTitle(c.ink, size: 17),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.lead(c.ink2),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            SrButton(label: actionLabel, icon: actionIcon, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class SrEmptyState extends StatelessWidget {
  const SrEmptyState({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Defaults to the generic "Nothing here yet".
  final String? title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return _StateLayout(
      icon: icon,
      fill: c.tint,
      ink: c.accent,
      title: title ?? context.l10n.emptyGeneric,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class SrNoAccess extends StatelessWidget {
  const SrNoAccess({super.key, this.actionLabel, this.onAction});

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return _StateLayout(
      icon: Icons.lock_outline_rounded,
      fill: c.avatarBg,
      ink: c.ink2,
      title: context.l10n.noAccessTitle,
      message: context.l10n.noAccessBody,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class SrPlanLocked extends StatelessWidget {
  const SrPlanLocked({super.key, this.onAction, this.title, this.message});

  /// Opens the plans screen; the button is hidden when null.
  final VoidCallback? onAction;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return _StateLayout(
      icon: Icons.workspace_premium_outlined,
      fill: c.goldTint,
      ink: c.gold,
      title: title ?? l10n.planLockedTitle,
      message: message ?? l10n.planLockedBody,
      actionLabel: onAction == null ? null : l10n.planLockedAction,
      onAction: onAction,
    );
  }
}

/// Explains [error]: an [SrDisplayableFailure] with status 0 reads as
/// offline, 402 as a plan limit, 403 forbidden, 404 not found; anything else
/// is generic, with the server's message under the title.
class SrErrorState extends StatelessWidget {
  const SrErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.onUpgrade,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgrade;

  /// A one-row banner for use inside lists and sheets.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final failure = switch (error) {
      final SrDisplayableFailure f => f,
      _ => null,
    };
    final status = failure?.statusCode ?? -1;
    final server = failure?.message.trim() ?? '';

    if (status == 402 && !compact) {
      return SrPlanLocked(
        onAction: onUpgrade,
        message: server.isEmpty ? null : server,
      );
    }

    final (icon, title, message) = switch (status) {
      0 => (Icons.wifi_off_rounded, l10n.errorOffline, l10n.errorOfflineBody),
      402 => (Icons.workspace_premium_outlined, l10n.planLockedTitle, server),
      403 => (
        Icons.lock_outline_rounded,
        l10n.noAccessTitle,
        server.isEmpty ? l10n.errorForbidden : server,
      ),
      404 => (Icons.search_off_rounded, l10n.errorNotFound, server),
      _ => (Icons.error_outline_rounded, l10n.errorGeneric, server),
    };
    final retry = status == 403 || status == 404 ? null : onRetry;

    if (compact) {
      return _ErrorBanner(
        icon: icon,
        title: title,
        message: message,
        onRetry: retry,
      );
    }
    return _StateLayout(
      icon: icon,
      fill: c.dangerTint,
      ink: c.danger,
      title: title,
      message: message,
      actionLabel: retry == null ? null : l10n.commonRetry,
      actionIcon: Icons.refresh_rounded,
      onAction: retry,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onRetry = this.onRetry;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: c.dangerTint,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.rowTitle(c.danger, size: 13.5)),
                if (message.isNotEmpty)
                  Text(message, style: AppText.meta(c.ink2, size: 12)),
              ],
            ),
          ),
          if (onRetry != null)
            SrButton(
              label: context.l10n.commonRetry,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.ghost,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

class SrSkeletonBox extends StatelessWidget {
  const SrSkeletonBox({
    super.key,
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    Widget box = _Shimmer(
      width: width,
      height: height,
      radius: radius,
      base: c.skeleton,
      highlight: c.skeletonGlow,
    );

    final factor = widthFactor;
    if (factor != null) {
      box = FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: factor,
        child: box,
      );
    }
    return box;
  }
}

/// One ticker drives every skeleton on screen; a controller per box meant
/// dozens of tickers per frame.
class _ShimmerClock {
  _ShimmerClock._();

  static final _ShimmerClock instance = _ShimmerClock._();

  static const int _periodMs = 930;

  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  Ticker? _ticker;
  int _listeners = 0;

  void attach() {
    _listeners++;
    if (_ticker != null) return;
    _ticker = Ticker((elapsed) {
      progress.value = (elapsed.inMilliseconds % _periodMs) / _periodMs;
    })..start();
  }

  void detach() {
    _listeners--;
    if (_listeners > 0) return;
    _listeners = 0;
    _ticker?.dispose();
    _ticker = null;
    progress.value = 0;
  }
}

/// A skeleton block lit by one screen-wide band that sweeps left to right,
/// so every block on the page shows the same band at the same moment.
class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.width,
    required this.height,
    required this.radius,
    required this.base,
    required this.highlight,
  });

  final double? width;
  final double height;
  final double radius;
  final Color base;
  final Color highlight;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> {
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate == _running) return;
    animate ? _ShimmerClock.instance.attach() : _ShimmerClock.instance.detach();
    _running = animate;
  }

  @override
  void dispose() {
    if (_running) _ShimmerClock.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: widget.width,
      height: widget.height,
      radius: widget.radius,
      base: widget.base,
      highlight: widget.highlight,
      screenWidth: MediaQuery.sizeOf(context).width,
      animate: _running,
    );
  }
}

class _ShimmerBox extends LeafRenderObjectWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.base,
    required this.highlight,
    required this.screenWidth,
    required this.animate,
  });

  final double? width;
  final double height;
  final double radius;
  final Color base;
  final Color highlight;
  final double screenWidth;
  final bool animate;

  @override
  _RenderShimmerBox createRenderObject(BuildContext context) =>
      _RenderShimmerBox(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderShimmerBox renderObject,
  ) {
    renderObject.spec = this;
  }
}

/// Paints the band in screen coordinates. Sweep range, band width and curve
/// are in screen widths.
class _RenderShimmerBox extends RenderBox {
  _RenderShimmerBox(this._spec);

  static const double _sweepFrom = -0.62;
  static const double _sweepTo = 1.37;
  static const double _bandHalfWidth = 0.587;
  static const Curve _sweepCurve = Curves.fastOutSlowIn;

  _ShimmerBox _spec;

  ValueNotifier<double> get _progress => _ShimmerClock.instance.progress;

  set spec(_ShimmerBox value) {
    final old = _spec;
    _spec = value;
    if (value.width != old.width || value.height != old.height) {
      markNeedsLayout();
    }
    if (attached && value.animate != old.animate) {
      value.animate
          ? _progress.addListener(markNeedsPaint)
          : _progress.removeListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_spec.animate) _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _spec.width ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) => _spec.width ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) => _spec.height;

  @override
  double computeMaxIntrinsicHeight(double width) => _spec.height;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final fill = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
    return constraints.constrain(Size(_spec.width ?? fill, _spec.height));
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()..color = _spec.base;
    if (_spec.animate) {
      paint.shader = _bandShader(offset.dx - localToGlobal(Offset.zero).dx);
    }
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(offset & size, Radius.circular(_spec.radius)),
      paint,
    );
  }

  Shader _bandShader(double screenLeft) {
    final sweep = _sweepCurve.transform(_progress.value);
    final centre =
        screenLeft +
        _spec.screenWidth * (_sweepFrom + (_sweepTo - _sweepFrom) * sweep);
    final halfWidth = _spec.screenWidth * _bandHalfWidth;
    return LinearGradient(
      colors: [_spec.base, _spec.highlight, _spec.base],
    ).createShader(Rect.fromLTRB(centre - halfWidth, 0, centre + halfWidth, 1));
  }
}

/// A placeholder shaped like an [SrListRow] with an avatar.
class SrSkeletonRow extends StatelessWidget {
  const SrSkeletonRow({super.key, this.titleFactor = 0.62});

  final double titleFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SrMetrics.rowMinHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SrSkeletonBox(width: 38, height: 38, radius: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SrSkeletonBox(widthFactor: titleFactor, height: 12),
                  const SizedBox(height: 8),
                  const SrSkeletonBox(widthFactor: 0.4, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SrSkeletonBox(width: 44, height: 10),
          ],
        ),
      ),
    );
  }
}

/// A placeholder shaped like a record card: avatar, two lines and two
/// action pills.
class SrSkeletonCard extends StatelessWidget {
  const SrSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SrSkeletonBox(width: 38, height: 38, radius: 19),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SrSkeletonBox(widthFactor: 0.62, height: 12),
                    SizedBox(height: 8),
                    SrSkeletonBox(widthFactor: 0.4, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(flex: 34, child: SrSkeletonBox(height: 28, radius: 8)),
              SizedBox(width: 10),
              Expanded(flex: 26, child: SrSkeletonBox(height: 28, radius: 8)),
              Spacer(flex: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// A loading list: [count] skeleton rows in one card, or [count] skeleton
/// cards when [cards]. Fills the space it is given without scrolling, or sizes
/// to its content when [shrinkWrap].
class SrSkeletonList extends StatelessWidget {
  const SrSkeletonList({
    super.key,
    this.count = 6,
    this.cards = false,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.fromLTRB(
      SrMetrics.gutter,
      14,
      SrMetrics.gutter,
      14,
    ),
  });

  final int count;
  final bool cards;
  final bool shrinkWrap;
  final EdgeInsets padding;

  static const List<double> _titleFactors = [0.62, 0.48, 0.7, 0.55, 0.66];

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    final Widget body = cards
        ? Column(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                const SrSkeletonCard(),
              ],
            ],
          )
        : SrCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: c.line,
                      indent: 16,
                      endIndent: 16,
                    ),
                  SrSkeletonRow(
                    titleFactor: _titleFactors[i % _titleFactors.length],
                  ),
                ],
              ],
            ),
          );

    final content = Semantics(
      label: context.l10n.dsLoading,
      child: Padding(padding: padding, child: body),
    );
    if (shrinkWrap) return content;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: content,
    );
  }
}

/// Renders an [AsyncValue]: [loading] (a skeleton list by default) while
/// loading, [SrErrorState] with retry on error, and [data] once loaded. Data
/// already shown stays while a refresh runs.
class SrAsyncView<T> extends StatelessWidget {
  const SrAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.onUpgrade,
    this.isEmpty,
    this.empty,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final WidgetBuilder? loading;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgrade;
  final bool Function(T data)? isEmpty;

  /// Shown instead of [data] when [isEmpty] holds; defaults to [SrEmptyState].
  final WidgetBuilder? empty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (loaded) {
        if (isEmpty?.call(loaded) ?? false) {
          return empty?.call(context) ?? const Center(child: SrEmptyState());
        }
        return data(context, loaded);
      },
      loading: () => loading?.call(context) ?? const SrSkeletonList(),
      error: (error, _) => Center(
        child: SingleChildScrollView(
          child: SrErrorState(
            error: error,
            onRetry: onRetry,
            onUpgrade: onUpgrade,
          ),
        ),
      ),
    );
  }
}
