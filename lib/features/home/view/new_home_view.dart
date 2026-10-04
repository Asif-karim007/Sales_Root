import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/view/widget/ai_guide.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/features/home/view/widget/quick_actions.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The lead the "Try a sample lead" link pre-fills the full form with.
final _sampleLead = Uri(
  path: Routes.leadNew,
  queryParameters: const {
    'name': 'Md. Karim',
    'phone': '+8801711000000',
    'company': 'Karim Textiles',
    'designation': 'Purchase Manager',
    'source': 'Referral',
  },
).toString();

/// #14: the home of a workspace with no data yet — the first-steps
/// checklist, quick adds and an empty lead card.
class NewHomeView extends ConsumerWidget {
  const NewHomeView({super.key, required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAddLead = ref.watch(
      moduleAccessProvider(AppModule.lead).select((a) => a.canAdd),
    );
    return HomeScrollView(
      children: [
        _FirstJobs(steps: summary.onboarding),
        const HomeQuickActions(),
        SrCard(
          child: SrEmptyState(
            icon: Icons.person_search_outlined,
            title: l10n.homeNoLeadsTitle,
            message: l10n.homeNoLeadsBody,
            actionLabel: canAddLead ? l10n.homeTrySample : null,
            onAction: canAddLead ? () => context.push(_sampleLead) : null,
          ),
        ),
        AiHintCard(message: l10n.homeAiNewHint),
      ],
    );
  }
}

class _FirstJobs extends ConsumerWidget {
  const _FirstJobs({required this.steps});

  final OnboardingSteps steps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final lead = ref.watch(moduleAccessProvider(AppModule.lead));
    final task = ref.watch(moduleAccessProvider(AppModule.task));
    final scan = ref.watch(moduleAccessProvider(AppModule.cardScan));
    VoidCallback? push(bool allowed, String location) =>
        allowed ? () => context.push(location) : null;
    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(
            title: l10n.homeFirstJobsTitle,
            actionLabel:
                '${fmt.number(steps.done)}/${fmt.number(OnboardingSteps.total)}',
          ),
          const SizedBox(height: 10),
          SrProgressBar(value: steps.done / OnboardingSteps.total),
          const SizedBox(height: 6),
          _Job(label: l10n.homeJobOpenAccount, done: true),
          _Job(
            label: l10n.homeJobAddLead,
            done: steps.leadAdded,
            onTap: push(lead.canAdd, Routes.leadQuick),
          ),
          _Job(
            label: l10n.homeJobLogCall,
            done: steps.callLogged,
            onTap: lead.canEdit
                ? () => context.go('${Routes.leads}?pick=call')
                : null,
          ),
          _Job(
            label: l10n.homeJobFollowUp,
            done: steps.followUpSet,
            onTap: push(task.canAdd, Routes.taskNew),
          ),
          _Job(
            label: l10n.homeJobScanCard,
            done: steps.cardScanned,
            onTap: push(scan.canAdd, Routes.scan),
          ),
        ],
      ),
    );
  }
}

class _Job extends StatelessWidget {
  const _Job({required this.label, required this.done, this.onTap});

  final String label;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final style = done
        ? AppText.body(
            c.ink3,
            size: 13.5,
          ).copyWith(decoration: TextDecoration.lineThrough)
        : AppText.body(c.ink, size: 13.5);
    return InkWell(
      onTap: done ? null : onTap,
      borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: done ? c.accent : c.ink3,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: style)),
            if (!done && onTap != null)
              Icon(Icons.chevron_right_rounded, size: 18, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
