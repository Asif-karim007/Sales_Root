import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/home_variant.dart';
import 'package:salesroot/features/home/providers/home_providers.dart';
import 'package:salesroot/features/home/view/easy_home_view.dart';
import 'package:salesroot/features/home/view/manager_home_view.dart';
import 'package:salesroot/features/home/view/new_home_view.dart';
import 'package:salesroot/features/home/view/owner_home_view.dart';
import 'package:salesroot/features/home/view/standard_home_view.dart';
import 'package:salesroot/features/home/view/team_lead_home_view.dart';
import 'package:salesroot/features/home/view/widget/ai_guide.dart';
import 'package:salesroot/features/home/view/widget/failure_text.dart';
import 'package:salesroot/features/home/view/widget/home_header.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/features/home/view/widget/home_skeleton.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The Home tab: the shared header over the home that fits the workspace,
/// role and experience level (see [homeVariantFor]).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(homeSummaryProvider);
    final variant = ref.watch(homeVariantProvider);
    ref.listen(homeSummaryProvider, (_, next) {
      final error = next.error;
      if (error != null && next.hasValue && !next.isLoading) {
        showSrError(context, failureText(context, error));
      }
    });
    return SrScaffold(
      appBar: HomeHeader(
        role: switch (variant) {
          HomeVariant.teamLead => l10n.homeRoleTeamLead,
          HomeVariant.manager => l10n.homeRoleManager,
          _ => null,
        },
      ),
      floatingAction: const AiGuideButton(),
      body: _body(context, ref, summary, variant),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<HomeSummary> summary,
    HomeVariant? variant,
  ) {
    final data = summary.value;
    if (summary.isLoading && (data == null || summary.isReloading)) {
      return const HomeSkeleton();
    }
    final error = summary.error;
    if (data == null || variant == null) {
      return HomeScrollView(
        children: [
          if (error != null)
            SrErrorState(
              error: error,
              onRetry: () => ref.invalidate(homeSummaryProvider),
              onUpgrade: () => context.push(_upgradeRoute(error)),
            ),
        ],
      );
    }
    return switch (variant) {
      HomeVariant.newUser => NewHomeView(summary: data),
      HomeVariant.easy => EasyHomeView(summary: data),
      HomeVariant.standard => StandardHomeView(summary: data),
      HomeVariant.teamLead => TeamLeadHomeView(summary: data),
      HomeVariant.manager => ManagerHomeView(summary: data),
      HomeVariant.owner => OwnerHomeView(summary: data),
    };
  }

  String _upgradeRoute(Object error) {
    final kind = error is ApiFailure ? error.quota?.name : null;
    return Uri(
      path: Routes.planChoose,
      queryParameters: {'reason': 'quota', 'kind': ?kind},
    ).toString();
  }
}
