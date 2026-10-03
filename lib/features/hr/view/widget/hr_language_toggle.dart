import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The language pill the prototype shows in every HR app bar.
class HrLanguageToggle extends ConsumerWidget {
  const HrLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBangla = ref.watch(appLocaleProvider) == bangla;
    return SrLanguageToggle(
      isBangla: isBangla,
      onChanged: (value) =>
          ref.read(appLocaleProvider.notifier).set(value ? bangla : english),
    );
  }
}
