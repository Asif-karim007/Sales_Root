import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #147 The SMS credit balance and how credits are counted.
class SmsCreditsScreen extends ConsumerWidget {
  const SmsCreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthCreditsTitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(smsCreditsProvider),
        onRetry: () => ref.invalidate(planProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, credits) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            GrowthInfoCard(
              lines: [(l10n.growthCreditsBalance, context.fmt.number(credits))],
            ),
            const SizedBox(height: 12),
            SrNote(message: l10n.growthCreditsRule),
          ],
        ),
      ),
    );
  }
}
