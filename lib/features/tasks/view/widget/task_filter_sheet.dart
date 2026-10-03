import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/task_pickers.dart';
import 'package:salesroot/features/tasks/view/widget/task_type_style.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

Future<void> showTaskFilterSheet(BuildContext context) => showSrSheet<void>(
  context: context,
  builder: (_) => const _TaskFilterSheet(),
);

/// Whose tasks (owners and team leads only) and which type.
class _TaskFilterSheet extends ConsumerStatefulWidget {
  const _TaskFilterSheet();

  @override
  ConsumerState<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends ConsumerState<_TaskFilterSheet> {
  late TaskFilter _filter = ref.read(taskFilterProvider);

  void _set(TaskFilter filter) => setState(() => _filter = filter);

  void _apply(TaskFilter filter) {
    ref.read(taskFilterProvider.notifier).apply(filter);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = ref.watch(currentRoleProvider) != WorkspaceRole.member;

    return SrSheet(
      title: l10n.tasksFilterTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (team) ...[
              SrFieldLabel(l10n.tasksFilterWho),
              const SizedBox(height: 8),
              _WhoChips(filter: _filter, onChanged: _set),
              if (_filter.who == TaskWho.member) ...[
                const SizedBox(height: 10),
                _MemberField(filter: _filter, onChanged: _set),
              ],
              const SizedBox(height: 18),
            ],
            SrFieldLabel(l10n.tasksFilterType),
            const SizedBox(height: 8),
            _TypeChips(filter: _filter, onChanged: _set),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.commonClear,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: () => _apply(const TaskFilter()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.commonApply,
                    expand: true,
                    onPressed:
                        _filter.who == TaskWho.member &&
                            _filter.memberId == null
                        ? null
                        : () => _apply(_filter),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhoChips extends StatelessWidget {
  const _WhoChips({required this.filter, required this.onChanged});

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final who in TaskWho.values)
          SrChip(
            label: switch (who) {
              TaskWho.mine => l10n.tasksFilterMine,
              TaskWho.everyone => l10n.tasksFilterEveryone,
              TaskWho.member => l10n.tasksFilterMember,
            },
            selected: filter.who == who,
            onTap: () => onChanged(
              TaskFilter(
                who: who,
                memberId: who == TaskWho.member ? filter.memberId : null,
                type: filter.type,
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberField extends ConsumerWidget {
  const _MemberField({required this.filter, required this.onChanged});

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final members = ref.watch(taskMembersProvider);
    final chosen = members.value?.firstWhereOrNull(
      (m) => m.id == filter.memberId,
    );
    return SrDropdownField(
      placeholder: l10n.tasksFilterPickMember,
      value: chosen?.name.of(bangla),
      icon: Icons.person_outline_rounded,
      error: members.hasError ? l10n.errorGeneric : null,
      onTap: () async {
        final list = members.value;
        if (list == null) {
          ref.invalidate(taskMembersProvider);
          return;
        }
        final picked = await pickMember(
          context,
          list,
          title: l10n.tasksFilterPickMember,
          currentId: filter.memberId,
        );
        if (picked == null) return;
        onChanged(
          TaskFilter(
            who: TaskWho.member,
            memberId: picked.id,
            type: filter.type,
          ),
        );
      },
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.filter, required this.onChanged});

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    TaskFilter withType(TaskType? type) =>
        TaskFilter(who: filter.who, memberId: filter.memberId, type: type);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        SrChip(
          label: l10n.tasksFilterAnyType,
          selected: filter.type == null,
          onTap: () => onChanged(withType(null)),
        ),
        for (final type in TaskType.values)
          SrChip(
            label: type.label(l10n),
            icon: type.icon,
            selected: filter.type == type,
            onTap: () => onChanged(withType(type)),
          ),
      ],
    );
  }
}
