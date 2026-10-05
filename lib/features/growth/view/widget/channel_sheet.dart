import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/whatsapp_connect_form.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Details of a WhatsApp or form channel: its embed code or link, and
/// connect, disconnect or switch on and off.
class ChannelSheet extends ConsumerWidget {
  const ChannelSheet({super.key, required this.channel});

  final LeadChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref
        .watch(moduleAccessProvider(AppModule.leadSources))
        .canEdit;
    final code = channel.isConnected ? channel.embedCode : null;
    final link = channel.isConnected ? channel.shareUrl : null;
    final connectWhatsApp =
        canEdit && channel.kind == ChannelKind.whatsapp && !channel.isConnected;
    return SrSheet(
      title: channel.kind.label(l10n),
      subtitle: channel.account,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (channel.isConnected)
              _ConnectedCard(channel: channel)
            else
              SrNote(message: _hint(l10n)),
            if (code != null) ...[
              const SizedBox(height: 12),
              _CodeBox(text: code),
              const SizedBox(height: 8),
              SrButton(
                label: l10n.growthChannelCopyCode,
                icon: Icons.copy_rounded,
                variant: SrButtonVariant.secondary,
                onPressed: () => _copy(context, code),
              ),
            ],
            if (link != null) ...[
              const SizedBox(height: 12),
              _CodeBox(text: link),
              const SizedBox(height: 8),
              _LinkButtons(link: link, onCopy: () => _copy(context, link)),
            ],
            if (connectWhatsApp) ...[
              const SizedBox(height: 12),
              const WhatsAppConnectForm(),
            ] else if (canEdit) ...[
              const SizedBox(height: 16),
              _action(context, ref),
            ],
          ],
        ),
      ),
    );
  }

  String _hint(AppLocalizations l10n) => switch (channel.kind) {
    ChannelKind.website => l10n.growthChannelWebsiteHint,
    ChannelKind.hostedForm => l10n.growthChannelHostedHint,
    ChannelKind.whatsapp => l10n.growthWhatsappHint,
    _ => l10n.growthChannelGenericHint,
  };

  Widget _action(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.read(channelActionsProvider.notifier);
    final integration = channel.integration;
    if (integration != null) {
      return SrButton(
        label: l10n.growthChannelDisconnect,
        variant: SrButtonVariant.danger,
        expand: true,
        onPressed: () => _run(
          context,
          actions.disconnect(integration.id),
          l10n.growthChannelDisconnected,
        ),
      );
    }
    final on = channel.isConnected;
    return SrButton(
      label: on ? l10n.growthChannelTurnOff : l10n.growthChannelTurnOn,
      variant: on ? SrButtonVariant.danger : SrButtonVariant.primary,
      expand: true,
      onPressed: () => _run(
        context,
        actions.setForm(
          channel.form,
          active: !on,
          name: l10n.growthChannelFormName,
        ),
        on ? l10n.growthChannelTurnedOff : l10n.growthChannelConnectedDone,
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<Object?> work,
    String done,
  ) async {
    final finished = await runGrowthTask(context, work);
    if (!finished || !context.mounted) return;
    showSrSuccess(context, done);
    Navigator.of(context).pop();
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSrInfo(context, context.l10n.growthCopied);
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.channel});

  final LeadChannel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final since = channel.integration?.connectedAt;
    final account = channel.account;
    return GrowthInfoCard(
      lines: [
        if (account != null)
          (
            l10n.growthChannelAccount,
            channel.kind == ChannelKind.whatsapp
                ? growthPhone(context, account)
                : account,
          ),
        (l10n.growthChannelStatus, l10n.growthChannelConnected),
        if (since != null) (l10n.growthChannelSince, fmt.date(since)),
      ],
    );
  }
}

class _LinkButtons extends StatelessWidget {
  const _LinkButtons({required this.link, required this.onCopy});

  final String link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: SrButton(
            label: l10n.growthChannelCopyLink,
            icon: Icons.copy_rounded,
            variant: SrButtonVariant.secondary,
            onPressed: onCopy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrButton(
            label: l10n.commonShare,
            icon: Icons.share_outlined,
            variant: SrButtonVariant.secondary,
            onPressed: () => SharePlus.instance.share(ShareParams(text: link)),
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        border: Border.all(color: c.line),
      ),
      child: SelectableText(text, style: AppText.meta(c.ink, size: 12.5)),
    );
  }
}
