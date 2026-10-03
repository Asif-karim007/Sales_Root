import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's language pill, wired to the app locale.
class TeamLanguageToggle extends ConsumerWidget {
  const TeamLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return SrLanguageToggle(
      isBangla: locale == bangla,
      onChanged: (toBangla) =>
          ref.read(appLocaleProvider.notifier).set(toBangla ? bangla : english),
    );
  }
}
