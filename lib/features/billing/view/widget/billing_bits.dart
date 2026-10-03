import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's language pill in the app bar.
class BillingLanguageAction extends ConsumerWidget {
  const BillingLanguageAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SrLanguageToggle(
    isBangla: ref.watch(appLocaleProvider) == bangla,
    onChanged: (isBangla) =>
        ref.read(appLocaleProvider.notifier).set(isBangla ? bangla : english),
  );
}

/// The prototype's `.price`: a bold amount with a small unit after it.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.amount,
    required this.unit,
    this.size = 18,
  });

  final int amount;
  final String unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: context.fmt.money(amount),
            style: AppText.metric(c.ink, size: size),
          ),
          TextSpan(text: unit, style: AppText.meta(c.ink2, size: 11.5)),
        ],
      ),
    );
  }
}

/// The prototype's `.line`: a label and a bold amount, hairline between rows;
/// the [total] row is larger.
class BillingLine extends StatelessWidget {
  const BillingLine({
    super.key,
    required this.label,
    required this.value,
    this.meta,
    this.total = false,
    this.valueColor,
    this.last = false,
  });

  final String label;
  final String value;
  final String? meta;
  final bool total;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final meta = this.meta;
    final ink = valueColor ?? c.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: total
                      ? AppText.rowTitle(c.ink, size: 15)
                      : AppText.lead(valueColor ?? c.ink2),
                ),
                if (meta != null)
                  Text(meta, style: AppText.meta(c.ink2, size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: total
                ? AppText.metric(ink, size: 17)
                : AppText.rowTitle(ink, size: 14),
          ),
        ],
      ),
    );
  }
}

/// A tick list, as in the prototype's `.checklist`.
class CheckList extends StatelessWidget {
  const CheckList({super.key, required this.items});

  final List<(String, String?)> items;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (title, detail) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: c.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CheckText(title: title, detail: detail),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CheckText extends StatelessWidget {
  const _CheckText({required this.title, required this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final detail = this.detail;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title, style: AppText.rowTitle(c.ink, size: 14)),
          if (detail != null && detail.isNotEmpty)
            TextSpan(
              text: ' — $detail',
              style: AppText.lead(c.ink2, size: 13.5),
            ),
        ],
      ),
    );
  }
}

/// The big success tick of `.bigcheck`.
class BigCheck extends StatelessWidget {
  const BigCheck({super.key, this.icon = Icons.check_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: c.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 38, color: c.onAccent),
    );
  }
}

/// Calls [onLoadMore] when the list nears its end.
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.onLoadMore,
    required this.child,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (note) {
        if (note.metrics.extentAfter < 400) onLoadMore();
        return false;
      },
      child: child,
    );
  }
}

/// The row under a paged list: a skeleton while the next page loads, or the
/// error with a retry.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SrErrorState(error: error, onRetry: onRetry, compact: true),
      );
    }
    if (!loading) return const SizedBox.shrink();
    return const SrSkeletonList(
      count: 2,
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 12),
    );
  }
}
