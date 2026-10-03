import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/features/settings/models/more_entry.dart';

part 'more_providers.g.dart';

/// The More menu: every entry the role, plan and level let the user see,
/// grouped. Entries the plan locks stay, marked [MoreItem.locked].
@riverpod
List<MoreSection> moreSections(Ref ref) {
  final sections = <MoreSection>[];
  for (final group in MoreGroup.values) {
    final items = [
      for (final entry in MoreEntry.values)
        if (entry.group == group) ?_item(ref, entry),
    ];
    if (items.isNotEmpty) sections.add(MoreSection(group, items));
  }
  return sections;
}

MoreItem? _item(Ref ref, MoreEntry entry) {
  final module = entry.module;
  if (module == null) return MoreItem(entry);
  final access = ref.watch(moduleAccessProvider(module));
  if (access.visible) return MoreItem(entry);
  if (access.lockedByPlan) return MoreItem(entry, locked: true);
  return null;
}
