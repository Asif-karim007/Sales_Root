import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/shell/add_sheet.dart';
import 'package:salesroot/core/shell/shell_tabs.dart';
import 'package:salesroot/features/settings/providers/push_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The tab shell: the current branch above the floating bottom bar.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pushRegistrationProvider, (_, _) {});
    final tabs = ref.watch(shellTabsProvider);
    final current = tabs.indexWhere((t) => t.index == shell.currentIndex);
    return SrScaffold(
      safeArea: false,
      body: shell,
      bottomBar: SrTabBar(
        index: current < 0 ? 0 : current,
        items: [for (final tab in tabs) _item(context, tab)],
        onAdd: () => AddSheet.show(context),
        onChanged: (i) => shell.goBranch(
          tabs[i].index,
          initialLocation: tabs[i].index == shell.currentIndex,
        ),
      ),
    );
  }

  SrTabItem _item(BuildContext context, ShellBranch tab) {
    final l10n = context.l10n;
    return switch (tab) {
      ShellBranch.home => SrTabItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      ShellBranch.leads => SrTabItem(
        icon: Icons.people_alt_outlined,
        activeIcon: Icons.people_alt_rounded,
        label: l10n.navLeads,
      ),
      ShellBranch.tasks => SrTabItem(
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: l10n.navTasks,
      ),
      ShellBranch.sales => SrTabItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
        label: l10n.navSales,
      ),
      ShellBranch.team => SrTabItem(
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups_rounded,
        label: l10n.navTeam,
      ),
      ShellBranch.more => SrTabItem(
        icon: Icons.menu_rounded,
        label: l10n.navMore,
      ),
    };
  }
}
