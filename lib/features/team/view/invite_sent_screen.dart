import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/external_links.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #67 `invitesent`: the invite went out; send the link another way.
class InviteSentScreen extends ConsumerWidget {
  const InviteSentScreen({super.key, required this.inviteId});

  final String inviteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final invite = ref.watch(inviteProvider(inviteId));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamInviteSentTitle,
        showBack: false,
        actions: const [TeamLanguageToggle()],
      ),
      footer: Row(
        children: [
          Expanded(
            child: SrButton(
              label: l10n.teamInviteAnother,
              variant: SrButtonVariant.secondary,
              expand: true,
              onPressed: () => context.pushReplacement(Routes.teamInvite),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SrButton(
              label: l10n.teamBackToTeam,
              expand: true,
              onPressed: () => context.go(Routes.team),
            ),
          ),
        ],
      ),
      body: SrAsyncView(
        value: invite,
        onRetry: () => ref.invalidate(inviteProvider(inviteId)),
        data: (context, invite) => _Sent(invite: invite),
      ),
    );
  }
}

class _Sent extends ConsumerWidget {
  const _Sent({required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final workspace = ref.watch(
      currentWorkspaceProvider.select((w) => w?.name ?? ''),
    );
    final phone = invite.phone ?? '';
    final message = l10n.teamInviteMessage(workspace, context.phone(phone));
    final level = invite.level;
    final managerName = invite.managerName;
    final expires = invite.expiresAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        30,
        SrMetrics.gutter,
        24,
      ),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 36, color: c.accent),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.teamInviteSentTo(invite.label),
          textAlign: TextAlign.center,
          style: AppText.sectionTitle(c.ink, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.teamInviteSentSms,
          textAlign: TextAlign.center,
          style: AppText.lead(c.ink2),
        ),
        const SizedBox(height: 18),
        InfoCard(
          lines: [
            InfoLine(l10n.teamRole, context.roleLabel(invite.role)),
            if (managerName != null)
              InfoLine(l10n.teamReportsTo, context.name(managerName)),
            InfoLine(
              l10n.teamLevel,
              level == null
                  ? l10n.teamLevelTheirChoice
                  : context.levelLabel(level),
            ),
            if (expires != null)
              InfoLine(l10n.teamInviteExpires, context.fmt.date(expires)),
          ],
        ),
        const SizedBox(height: 14),
        _ShareGrid(
          buttons: [
            if (phone.isNotEmpty) ...[
              _ShareButton(
                label: l10n.teamInviteWhatsApp,
                icon: Icons.chat_outlined,
                onTap: () => openExternal(context, whatsAppUri(phone, message)),
              ),
              _ShareButton(
                label: l10n.teamInviteSms,
                icon: Icons.sms_outlined,
                onTap: () => openExternal(context, smsUri(phone, message)),
              ),
            ],
            _ShareButton(
              label: l10n.commonShare,
              icon: Icons.ios_share_rounded,
              onTap: () => SharePlus.instance.share(ShareParams(text: message)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareButton {
  const _ShareButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Two buttons to a row.
class _ShareGrid extends StatelessWidget {
  const _ShareGrid({required this.buttons});

  final List<_ShareButton> buttons;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < buttons.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var j = i; j < i + 2; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(
                  child: j < buttons.length
                      ? SrButton(
                          label: buttons[j].label,
                          icon: buttons[j].icon,
                          size: SrButtonSize.sm,
                          variant: SrButtonVariant.secondary,
                          expand: true,
                          onPressed: buttons[j].onTap,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
