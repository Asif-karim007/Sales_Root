import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/auth_links.dart';
import 'package:salesroot/features/auth/models/invitation.dart';
import 'package:salesroot/features/auth/providers/invite_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/role_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #10. Signed out, joining verifies the number first and comes back here;
/// signed in, it joins and switches to the team.
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final invitation = ref.watch(invitationProvider(code));
    final signedIn = ref.watch(sessionProvider.select((s) => s.value != null));
    final action = ref.watch(inviteActionProvider(code));
    final notifier = ref.read(inviteActionProvider(code).notifier);
    ref.listen(inviteActionProvider(code), (previous, next) {
      switch (next) {
        case AsyncData(value: InviteOutcome.accepted):
          final name = invitation.value?.workspaceName ?? '';
          showSrSuccess(context, l10n.authInviteJoined(name));
          context.go(Routes.home);
        case AsyncData(value: InviteOutcome.declined):
          context.go(signedIn ? Routes.home : Routes.welcome);
        case AsyncError(:final error):
          showSrError(context, authFailureText(l10n, error));
        default:
      }
    });
    final busy = action.isLoading;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authInviteAppBar,
        actions: const [AuthLanguageToggle()],
      ),
      footer: invitation.hasValue
          ? Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.authInviteDecline,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: busy ? null : notifier.decline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.authInviteJoin,
                    expand: true,
                    loading: busy,
                    onPressed: signedIn
                        ? notifier.accept
                        : () => context.push(AuthLinks.phone(invite: code)),
                  ),
                ),
              ],
            )
          : null,
      body: SrAsyncView(
        value: invitation,
        onRetry: () => ref.invalidate(invitationProvider(code)),
        loading: (_) => const _InviteSkeleton(),
        data: (context, invitation) => _InviteBody(invitation: invitation),
      ),
    );
  }
}

class _InviteBody extends StatelessWidget {
  const _InviteBody({required this.invitation});

  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final inviter = invitation.inviter.of(context.fmt.isBangla);
    final points = [
      l10n.authInvitePointLeads,
      l10n.authInvitePointChats,
      l10n.authInvitePointLocation,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SrAvatar(
              name: invitation.workspaceName,
              size: 72,
              tone: SrAvatarTone.dark,
            ),
          ),
          const SizedBox(height: 14),
          AuthIntro(
            center: true,
            title: l10n.authInviteTitle(invitation.workspaceName),
            lead: Text(
              l10n.authInviteLead(inviter, invitation.role.label(l10n)),
            ),
          ),
          const SizedBox(height: 20),
          SrCard(
            tone: SrCardTone.tint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                for (var i = 0; i < points.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: c.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          points[i],
                          style: AppText.body(c.ink, size: 13.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteSkeleton extends StatelessWidget {
  const _InviteSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 34, 20, 24),
    child: Column(
      children: [
        SrSkeletonBox(width: 72, height: 72, radius: 36),
        SizedBox(height: 16),
        SrSkeletonBox(widthFactor: 0.6, height: 22),
        SizedBox(height: 10),
        SrSkeletonBox(widthFactor: 0.8, height: 14),
        SizedBox(height: 24),
        SrSkeletonBox(height: 110, radius: SrMetrics.radiusCard),
      ],
    ),
  );
}
