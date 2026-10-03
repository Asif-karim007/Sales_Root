import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #8: what the app offers. "Let's go" continues to a pending invitation,
/// to creating a team for those who run one, or home.
class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final features = [
      (Icons.mic_none_rounded, l10n.authFeatureVoice),
      (Icons.badge_outlined, l10n.authFeatureCards),
      (Icons.event_outlined, l10n.authFeatureReminders),
      (Icons.wifi_off_rounded, l10n.authFeatureOffline),
      (Icons.groups_outlined, l10n.authFeatureTeam),
      (Icons.account_balance_wallet_outlined, l10n.authFeatureSales),
    ];

    void go() {
      final flow = ref.read(signUpFlowProvider);
      final invite = flow.inviteCode;
      ref.read(signUpFlowProvider.notifier).clear();
      if (invite != null) {
        context.go(Routes.acceptInviteFor(invite));
      } else if (flow.workStyle == WorkStyle.team) {
        context.go(Routes.createTeam);
      } else {
        context.go(Routes.home);
      }
    }

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authFeaturesAppBar,
        actions: const [AuthLanguageToggle()],
      ),
      footer: SrButton(label: l10n.authFeaturesGo, expand: true, onPressed: go),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthIntro(title: l10n.authFeaturesTitle),
            const SizedBox(height: 14),
            SrCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Column(
                children: [
                  for (var i = 0; i < features.length; i++)
                    SrListRow(
                      leading: SrAvatar(
                        icon: features[i].$1,
                        tone: SrAvatarTone.accent,
                      ),
                      title: features[i].$2,
                      divider: i < features.length - 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SrNote(
              message: l10n.authFeaturesFree,
              tone: SrNoteTone.gold,
              icon: Icons.star_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
