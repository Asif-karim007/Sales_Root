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
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Details of a non-Facebook channel: its embed code or link, and connect or
/// disconnect.
class ChannelSheet extends ConsumerWidget {
  const ChannelSheet({super.key, required this.channel});

  final LeadChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final canEdit = ref
        .watch(moduleAccessProvider(AppModule.leadSources))
        .canEdit;
    final code = channel.embedCode;
    final link = channel.shareUrl;
    return SrSheet(
      title: channel.kind.label(l10n),
      subtitle: channel.account,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (channel.isConnected)
              GrowthInfoCard(
                lines: [
                  (l10n.growthChannelLeadsAll, fmt.number(channel.leadCount)),
                  (
                    l10n.growthChannelsLeadsWeek,
                    fmt.number(channel.leadsThisWeek),
                  ),
                ],
              )
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
              Row(
                children: [
                  Expanded(
                    child: SrButton(
                      label: l10n.growthChannelCopyLink,
                      icon: Icons.copy_rounded,
                      variant: SrButtonVariant.secondary,
                      onPressed: () => _copy(context, link),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SrButton(
                      label: l10n.commonShare,
                      icon: Icons.share_outlined,
                      variant: SrButtonVariant.secondary,
                      onPressed: () =>
                          SharePlus.instance.share(ShareParams(text: link)),
                    ),
                  ),
                ],
              ),
            ],
            if (canEdit) ...[const SizedBox(height: 16), _action(context, ref)],
          ],
        ),
      ),
    );
  }

  String _hint(AppLocalizations l10n) => switch (channel.kind) {
    ChannelKind.website => l10n.growthChannelWebsiteHint,
    ChannelKind.hostedForm => l10n.growthChannelHostedHint,
    ChannelKind.email => l10n.growthChannelEmailHint,
    _ => l10n.growthChannelGenericHint,
  };

  Widget _action(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.read(channelActionsProvider.notifier);
    if (channel.isConnected) {
      return SrButton(
        label: l10n.growthChannelDisconnect,
        variant: SrButtonVariant.danger,
        expand: true,
        onPressed: () => _run(
          context,
          actions.disconnect(channel.id),
          l10n.growthChannelDisconnected,
        ),
      );
    }
    return SrButton(
      label: switch (channel.kind) {
        ChannelKind.website => l10n.growthChannelCodeAdded,
        ChannelKind.hostedForm => l10n.growthChannelTurnOn,
        _ => l10n.growthChannelConnect,
      },
      expand: true,
      onPressed: () => _run(
        context,
        actions.connect(channel.id),
        l10n.growthChannelConnectedDone,
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<LeadChannel> work,
    String done,
  ) async {
    final result = await runGrowthAction(context, work);
    if (result == null || !context.mounted) return;
    showSrSuccess(context, done);
    Navigator.of(context).pop();
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSrInfo(context, context.l10n.growthCopied);
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
