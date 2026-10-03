import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/models/more_entry.dart';
import 'package:salesroot/features/settings/providers/more_providers.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/more_labels.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #84: who you are, then every module you can open, grouped.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sections = ref.watch(moreSectionsProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsMoreTitle,
        showBack: false,
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          const _ProfileCard(),
          for (final section in sections) ...[
            const SizedBox(height: 18),
            SrSectionHeader(title: section.group.label(l10n)),
            const SizedBox(height: 8),
            SrStatGrid(
              columns: 2,
              spacing: 8,
              tiles: [for (final item in section.items) _Tile(item: item)],
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 18),
            SrRowGroup(
              rows: [
                SrListRow(
                  title: l10n.settingsMoreDeveloper,
                  leading: const RowIcon(Icons.developer_mode_rounded),
                  chevron: true,
                  onTap: () => context.push(Routes.dev),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const _VersionLine(),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider).value;
    final workspace = ref.watch(currentWorkspaceProvider);
    final role = ref.watch(currentRoleProvider);
    final plan = ref.watch(planProvider).value;
    final billing = ref.watch(moduleAccessProvider(AppModule.billing));
    final name = session?.name ?? '';
    final phone = session?.phone;
    final details = [
      if (phone != null) context.fmt.phone(phone),
      ?workspace?.name,
      role.label(l10n),
    ].join(' · ');

    return SrCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SrListRow(
            title: name,
            subtitle: details,
            leading: SrAvatar(name: name, size: 48, tone: SrAvatarTone.accent),
            chevron: true,
            onTap: () => context.push(Routes.settings),
          ),
          if (plan != null) ...[
            Divider(height: 1, color: c.line, indent: 16, endIndent: 16),
            _PlanRow(plan: plan, canOpen: billing.visible),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.canOpen});

  final Plan plan;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final renewsAt = plan.renewsAt;
    return SrListRow(
      title: l10n.settingsMorePlan(plan.name),
      subtitle: renewsAt == null || plan.pricePerMonth == 0
          ? null
          : l10n.settingsMorePlanRenews(context.fmt.date(renewsAt)),
      leading: const RowIcon(
        Icons.workspace_premium_outlined,
        tone: SrAvatarTone.gold,
      ),
      chevron: canOpen,
      onTap: canOpen ? () => context.push(Routes.planUsage) : null,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final MoreItem item;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final entry = item.entry;
    final gold = entry == MoreEntry.refer;
    return SrCard(
      tone: gold ? SrCardTone.gold : SrCardTone.plain,
      padding: const EdgeInsets.all(12),
      onTap: () => item.locked || !entry.branch
          ? context.push(item.target)
          : context.go(item.target),
      child: Row(
        children: [
          Icon(entry.icon, size: 20, color: gold ? c.gold : c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.label(context.l10n),
              style: AppText.rowTitle(c.ink, size: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.locked)
            Icon(Icons.lock_outline_rounded, size: 16, color: c.ink3),
        ],
      ),
    );
  }
}

class _VersionLine extends ConsumerWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final version = ref.watch(appVersionProvider).value;
    return Text(
      context.l10n.settingsMoreVersion(context.fmt.digits(version ?? '')),
      textAlign: TextAlign.center,
      style: AppText.meta(c.ink3, size: 11.5),
    );
  }
}
