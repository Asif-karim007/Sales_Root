import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #135 The Facebook Page that sends lead forms and Messenger chats.
class FacebookConnectScreen extends ConsumerWidget {
  const FacebookConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthFacebookTitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(facebookPageProvider),
        onRetry: () => ref.invalidate(integrationsProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, page) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: page == null
              ? [
                  const _SignInCard(),
                  const SizedBox(height: 12),
                  SrNote(message: l10n.growthFacebookNotConnected),
                ]
              : [
                  _PageCard(page: page),
                  const SizedBox(height: 12),
                  _DisconnectButton(page: page),
                ],
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SrAvatar(
            icon: Icons.facebook_rounded,
            tone: SrAvatarTone.accent,
            square: true,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.growthFacebookSignInTitle,
            style: AppText.sectionTitle(c.ink, size: 17),
          ),
          const SizedBox(height: 6),
          Text(l10n.growthFacebookSignInBody, style: AppText.lead(c.ink2)),
          const SizedBox(height: 12),
          for (final line in [
            l10n.growthFacebookSignInPoint1,
            l10n.growthFacebookSignInPoint2,
            l10n.growthFacebookSignInPoint3,
          ])
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(line, style: AppText.body(c.ink, size: 14)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.page});

  final Integration page;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final since = page.connectedAt;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.facebook_rounded,
            tone: SrAvatarTone.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.displayName ?? l10n.growthChannelFacebook,
                  style: AppText.rowTitle(c.ink, size: 15),
                ),
                if (since != null)
                  Text(
                    l10n.growthFacebookConnectedSince(context.fmt.date(since)),
                    style: AppText.meta(c.ink2),
                  ),
              ],
            ),
          ),
          SrTag(l10n.growthChannelConnected, tone: SrTone.ok),
        ],
      ),
    );
  }
}

class _DisconnectButton extends ConsumerWidget {
  const _DisconnectButton({required this.page});

  final Integration page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref
        .watch(moduleAccessProvider(AppModule.leadSources))
        .canEdit;
    if (!canEdit) return const SizedBox.shrink();
    return SrButton(
      label: l10n.growthFacebookDisconnect,
      variant: SrButtonVariant.ghost,
      icon: Icons.link_off_rounded,
      onPressed: () async {
        final confirmed = await showSrConfirm(
          context,
          title: l10n.growthFacebookDisconnectTitle,
          message: l10n.growthFacebookDisconnectBody,
          confirmLabel: l10n.growthChannelDisconnect,
          icon: Icons.link_off_rounded,
          destructive: true,
        );
        if (!confirmed || !context.mounted) return;
        final done = await runGrowthTask(
          context,
          ref.read(channelActionsProvider.notifier).disconnect(page.id),
        );
        if (done && context.mounted) {
          showSrSuccess(context, l10n.growthChannelDisconnected);
        }
      },
    );
  }
}
