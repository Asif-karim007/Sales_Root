import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The `.langpill` in the auth app bars, wired to the app locale.
class AuthLanguageToggle extends ConsumerWidget {
  const AuthLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBangla = ref.watch(appLocaleProvider) == bangla;
    return SrLanguageToggle(
      isBangla: isBangla,
      onChanged: (toBangla) =>
          ref.read(appLocaleProvider.notifier).set(toBangla ? bangla : english),
    );
  }
}
