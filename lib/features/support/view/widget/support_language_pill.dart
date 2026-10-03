import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The app bar's বাং / EN pill, wired to the app language.
class SupportLanguagePill extends ConsumerWidget {
  const SupportLanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SrLanguageToggle(
    isBangla: ref.watch(appLocaleProvider) == bangla,
    onChanged: (isBangla) =>
        ref.read(appLocaleProvider.notifier).set(isBangla ? bangla : english),
  );
}
