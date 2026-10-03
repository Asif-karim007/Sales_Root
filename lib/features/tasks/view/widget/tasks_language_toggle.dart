import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The header's বাং / EN pill, wired to the app locale.
class TasksLanguageToggle extends ConsumerWidget {
  const TasksLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SrLanguageToggle(
    isBangla: ref.watch(appLocaleProvider) == bangla,
    onChanged: (toBangla) =>
        ref.read(appLocaleProvider.notifier).set(toBangla ? bangla : english),
  );
}
