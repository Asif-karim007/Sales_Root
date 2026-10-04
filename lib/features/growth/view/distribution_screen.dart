import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/providers/distribution_providers.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/rule_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #139 The rules that share new leads out, first match wins.
class DistributionScreen extends ConsumerWidget {
  const DistributionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.distribution));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthRulesTitle,
        actions: [
          const GrowthLanguageAction(),
          if (access.canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.growthRuleNew,
              onTap: () => context.push(Routes.distributionRuleFor(0)),
            ),
        ],
      ),
      body: SrAsyncView(
        value: ref.watch(distributionProvider),
        onRetry: () => ref.invalidate(distributionProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 5),
        data: (context, settings) => RefreshIndicator(
          onRefresh: () => ref.read(distributionProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              _MasterSwitch(settings: settings),
              const SizedBox(height: 16),
              SrSectionHeader(
                title: l10n.growthRulesOrder,
                actionLabel: l10n.growthRulesTest,
                onAction: () => ref.invalidate(ruleTestProvider),
              ),
              const SizedBox(height: 8),
              _Rules(settings: settings),
              const SizedBox(height: 12),
              const _TestCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterSwitch extends ConsumerWidget {
  const _MasterSwitch({required this.settings});

  final DistributionSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref
        .watch(moduleAccessProvider(AppModule.distribution))
        .canEdit;
    return SrRowGroup(
      rows: [
        GrowthToggleRow(
          title: l10n.growthRulesOn,
          subtitle: l10n.growthRulesOnHint,
          value: settings.enabled,
          onChanged: canEdit
              ? (value) => runGrowthTask(
                  context,
                  ref.read(distributionProvider.notifier).setEnabled(value),
                )
              : null,
        ),
      ],
    );
  }
}

class _Rules extends ConsumerWidget {
  const _Rules({required this.settings});

  final DistributionSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.distribution));
    final members = ref.watch(growthMembersProvider).value ?? const [];
    final areas = ref.watch(ruleAreasProvider).value ?? const [];
    final words = RuleVocabulary(
      members: {for (final m in members) m.id: m},
      areas: {for (final a in areas) a.en: a},
    );
    if (settings.rules.isEmpty) {
      return SrEmptyState(
        icon: Icons.alt_route_rounded,
        title: l10n.growthRulesEmpty,
        message: l10n.growthRulesEmptyBody,
        actionLabel: access.canAdd ? l10n.growthRuleNew : null,
        onAction: access.canAdd
            ? () => context.push(Routes.distributionRuleFor(0))
            : null,
      );
    }
    return SrRowGroup(
      rows: [
        for (final rule in settings.rules)
          _RuleRow(
            rule: rule,
            summary: words.summary(context, rule),
            dimmed: !settings.enabled,
            canEdit: access.canEdit && rule.canEdit,
          ),
      ],
    );
  }
}

class _RuleRow extends ConsumerWidget {
  const _RuleRow({
    required this.rule,
    required this.summary,
    required this.dimmed,
    required this.canEdit,
  });

  final DistributionRule rule;
  final String summary;
  final bool dimmed;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final on = rule.enabled && !dimmed;
    return SrListRow(
      leading: Icon(Icons.drag_indicator_rounded, color: c.ink3),
      title: l10n.growthRuleNumbered(
        context.fmt.number(rule.position),
        rule.name,
      ),
      subtitle: summary,
      trailing: SrTag(
        on ? l10n.growthRuleOn : l10n.growthRuleOff,
        tone: on ? SrTone.ok : SrTone.neutral,
      ),
      onTap: () => context.push(Routes.distributionRuleFor(rule.id)),
      onLongPress: canEdit
          ? () async {
              final done = await runGrowthTask(
                context,
                ref
                    .read(distributionProvider.notifier)
                    .setRuleEnabled(rule.id, !rule.enabled),
              );
              if (!done || !context.mounted) return;
              showSrInfo(
                context,
                rule.enabled
                    ? l10n.growthRuleTurnedOff(rule.name)
                    : l10n.growthRuleTurnedOn(rule.name),
              );
            }
          : null,
    );
  }
}

class _TestCard extends ConsumerWidget {
  const _TestCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final test = ref.watch(ruleTestProvider);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: switch (test) {
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.growthRulesTestTitle(fmt.number(value.total)),
              style: AppText.rowTitle(c.ink, size: 14),
            ),
            const SizedBox(height: 8),
            for (final row in value.byRule)
              SrBarRow(
                label: l10n.growthRulesTestRule(fmt.number(row.position)),
                value: row.count.toDouble(),
                max: value.total.toDouble(),
              ),
            SrBarRow(
              label: l10n.growthModeQueue,
              value: value.queued.toDouble(),
              max: value.total.toDouble(),
              color: c.gold,
            ),
          ],
        ),
        AsyncError(:final error) => SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(ruleTestProvider),
        ),
        _ => const Column(
          children: [
            SrSkeletonBox(height: 14, widthFactor: 0.5),
            SizedBox(height: 12),
            SrSkeletonBox(height: 10),
            SizedBox(height: 10),
            SrSkeletonBox(height: 10),
          ],
        ),
      },
    );
  }
}
