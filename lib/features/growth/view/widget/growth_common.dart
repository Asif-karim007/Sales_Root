import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's language pill in an app bar.
class GrowthLanguageAction extends ConsumerWidget {
  const GrowthLanguageAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SrLanguageToggle(
    isBangla: ref.watch(appLocaleProvider) == bangla,
    onChanged: (isBangla) =>
        ref.read(appLocaleProvider.notifier).set(isBangla ? bangla : english),
  );
}

/// "4 min", "2 h", "3 d" for a wait or an age the server measured.
String growthAgo(BuildContext context, Duration age) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  if (age.inMinutes < 1) return l10n.growthAgoNow;
  if (age.inHours < 1) return l10n.growthAgoMinutes(fmt.number(age.inMinutes));
  if (age.inDays < 1) return l10n.growthAgoHours(fmt.number(age.inHours));
  return l10n.growthAgoDays(fmt.number(age.inDays));
}

/// "+880 1912 345 678" from "+8801912345678", in the screen's digits.
String growthPhone(BuildContext context, String raw) {
  final match = RegExp(r'^\+880(\d{4})(\d{3})(\d{3})$').firstMatch(raw);
  final grouped = match == null
      ? raw
      : '+880 ${match[1]} ${match[2]} ${match[3]}';
  return context.fmt.phone(grouped);
}

/// The text a snack shows for a failed call.
String growthFailureText(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! ApiFailure) return l10n.errorGeneric;
  if (error.isOffline) return l10n.errorOffline;
  if (error.isForbidden) return l10n.errorForbidden;
  final message = error.message.trim();
  return message.isEmpty ? l10n.errorGeneric : message;
}

/// Runs [work] behind the loader. A failure shows as a snack, except a 402
/// when [onQuota] is given.
Future<T?> runGrowthAction<T>(
  BuildContext context,
  Future<T> work, {
  VoidCallback? onQuota,
}) async {
  try {
    return await showSrLoader(context, work);
  } catch (error) {
    if (!context.mounted) return null;
    if (error is ApiFailure && error.isQuota && onQuota != null) {
      onQuota();
      return null;
    }
    showSrError(context, growthFailureText(context, error));
    return null;
  }
}

/// [runGrowthAction] for work with no result; true when it succeeded.
Future<bool> runGrowthTask(
  BuildContext context,
  Future<void> work, {
  VoidCallback? onQuota,
}) async {
  final done = await runGrowthAction(
    context,
    work.then((_) => true),
    onQuota: onQuota,
  );
  return done ?? false;
}

/// Rebuilds [builder] every [every], for timers that count up on screen.
class GrowthClock extends StatefulWidget {
  const GrowthClock({
    super.key,
    required this.builder,
    this.every = const Duration(seconds: 30),
  });

  final WidgetBuilder builder;
  final Duration every;

  @override
  State<GrowthClock> createState() => _GrowthClockState();
}

class _GrowthClockState extends State<GrowthClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// The prototype's `.line`: a label on the left, a bold value on the right.
class GrowthInfoLine extends StatelessWidget {
  const GrowthInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.divider = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: divider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.meta(c.ink2, size: 13.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.rowTitle(valueColor ?? c.ink, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card of [GrowthInfoLine]s.
class GrowthInfoCard extends StatelessWidget {
  const GrowthInfoCard({super.key, required this.lines});

  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) => SrCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    child: Column(
      children: [
        for (var i = 0; i < lines.length; i++)
          GrowthInfoLine(
            label: lines[i].$1,
            value: lines[i].$2,
            divider: i < lines.length - 1,
          ),
      ],
    ),
  );
}

/// The prototype's `.trow`: a title, an optional line under it and a switch.
class GrowthToggleRow extends StatelessWidget {
  const GrowthToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Null shows the switch disabled.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return SrListRow(
      title: title,
      subtitle: subtitle,
      trailing: SrSwitch(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged(!value),
    );
  }
}

/// A body of [header] widgets over one card of rows that loads the next
/// page near the end and refreshes on pull.
class GrowthPagedList<T> extends StatelessWidget {
  const GrowthPagedList({
    super.key,
    required this.paged,
    required this.row,
    required this.onLoadMore,
    required this.onRefresh,
    required this.empty,
    this.header = const [],
    this.title,
  });

  final Paged<T> paged;
  final Widget Function(T item) row;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget empty;
  final List<Widget> header;
  final String? title;

  bool _onScroll(ScrollNotification note) {
    if (note.metrics.extentAfter < 320 &&
        paged.hasMore &&
        !paged.isLoadingMore &&
        paged.loadMoreError == null) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final error = paged.loadMoreError;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicator(
        color: c.accent,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: SrScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            32,
          ),
          children: [
            for (final widget in header) ...[
              widget,
              const SizedBox(height: 12),
            ],
            if (paged.isEmpty)
              empty
            else
              SrRowGroup(
                title: title,
                rows: [for (final item in paged.items) row(item)],
              ),
            if (paged.isLoadingMore) ...[
              const SizedBox(height: 12),
              const SrSkeletonRow(),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              SrErrorState(error: error, compact: true, onRetry: onLoadMore),
            ],
          ],
        ),
      ),
    );
  }
}
