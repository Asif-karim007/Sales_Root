import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The app bar's বাং / EN pill.
class FfLanguageToggle extends ConsumerWidget {
  const FfLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return SrLanguageToggle(
      isBangla: locale == bangla,
      onChanged: (isBangla) =>
          ref.read(appLocaleProvider.notifier).set(isBangla ? bangla : english),
    );
  }
}
