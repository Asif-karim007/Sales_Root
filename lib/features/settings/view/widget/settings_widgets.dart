import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The app bar's বাং / EN pill, wired to the app locale.
class LanguageAction extends ConsumerWidget {
  const LanguageAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrLanguageToggle(
      isBangla: ref.watch(appLocaleProvider) == bangla,
      onChanged: (isBangla) =>
          ref.read(appLocaleProvider.notifier).set(isBangla ? bangla : english),
    );
  }
}

/// The prototype's `.trow`: a title, an optional line under it and a switch.
/// A null [onChanged] shows the switch disabled.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return SrListRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: SrSwitch(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged(!value),
    );
  }
}

/// A row's round icon, like the prototype's `.av` with an icon inside.
class RowIcon extends StatelessWidget {
  const RowIcon(this.icon, {super.key, this.tone = SrAvatarTone.neutral});

  final IconData icon;
  final SrAvatarTone tone;

  @override
  Widget build(BuildContext context) =>
      SrAvatar(icon: icon, tone: tone, size: 38);
}

/// A label over a value, for read-only facts such as storage sizes.
class FactLine extends StatelessWidget {
  const FactLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(c.ink2, size: 14))),
          Text(value, style: AppText.rowTitle(c.ink, size: 14)),
        ],
      ),
    );
  }
}

/// An [AsyncValue] rendered inside a scrolling page: skeleton rows while
/// loading, a one-row error banner with retry on failure.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.skeletonRows = 3,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final VoidCallback? onRetry;
  final int skeletonRows;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (loaded) => data(context, loaded),
      loading: () => SrCard(
        padding: EdgeInsets.zero,
        child: SrSkeletonList(
          count: skeletonRows,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
        ),
      ),
      error: (error, _) =>
          SrErrorState(error: error, onRetry: onRetry, compact: true),
    );
  }
}

/// Screen padding for scrolling bodies.
const screenPadding = EdgeInsets.fromLTRB(
  SrMetrics.gutter,
  14,
  SrMetrics.gutter,
  32,
);
