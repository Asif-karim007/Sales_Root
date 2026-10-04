import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/home/providers/notification_providers.dart';
import 'package:salesroot/features/home/view/workspace_switch_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Morning until noon, afternoon until five, evening after.
String homeGreeting(AppLocalizations l10n, DateTime now) => switch (now.hour) {
  >= 4 && < 12 => l10n.homeGreetingMorning,
  >= 12 && < 17 => l10n.homeGreetingAfternoon,
  _ => l10n.homeGreetingEvening,
};

/// The header every home shares: brand bar with language, search and the
/// bell, then the greeting and the workspace pill. [role] follows the
/// greeting for team leads and managers.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, this.role});

  final String? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = ref.watch(sessionProvider.select((s) => s.value?.name)) ?? '';
    final greeting = homeGreeting(l10n, DateTime.now());
    final role = this.role;
    return SrHeader(
      children: [
        const _BrandBar(),
        Row(
          children: [
            SrAvatar(name: name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: _Greeting(
                kicker: role == null
                    ? greeting
                    : l10n.homeGreetingRole(greeting, role),
                name: name,
              ),
            ),
            const SizedBox(width: 8),
            const _WorkspacePill(),
          ],
        ),
      ],
    );
  }
}

class _BrandBar extends ConsumerWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final isBangla = ref.watch(appLocaleProvider) == bangla;
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;
    return Row(
      children: [
        const SrAvatar(
          icon: Icons.eco_rounded,
          size: 28,
          square: true,
          tone: SrAvatarTone.accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(l10n.appName, style: AppText.rowTitle(c.ink, size: 15)),
        ),
        SrLanguageToggle(
          isBangla: isBangla,
          onChanged: (bn) =>
              ref.read(appLocaleProvider.notifier).set(bn ? bangla : english),
        ),
        const SizedBox(width: 8),
        SrIconButton(
          icon: Icons.search_rounded,
          tooltip: l10n.commonSearch,
          onTap: () => context.push(Routes.search),
        ),
        const SizedBox(width: 8),
        SrIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: l10n.homeNotificationsTitle,
          badgeCount: unread,
          onTap: () => context.push(Routes.notifications),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.kicker, required this.name});

  final String kicker;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: AppText.meta(c.ink2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          name,
          style: AppText.pageTitle(c.ink, size: 19),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _WorkspacePill extends ConsumerWidget {
  const _WorkspacePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final name = ref.watch(currentWorkspaceProvider.select((w) => w?.name));
    if (name == null) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: context.l10n.homeWorkspaceSwitch,
      child: Material(
        color: c.canvas,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showWorkspaceSwitcher(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: AppText.chip(c.ink, size: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded, size: 18, color: c.ink2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
