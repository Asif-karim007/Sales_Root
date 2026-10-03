import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';
import 'package:salesroot/features/growth/view/widget/channel_sheet.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #134 Lead sources and channels.
class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthChannelsTitle,
        subtitle: l10n.growthChannelsSubtitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(leadChannelsProvider),
        onRetry: () => ref.invalidate(leadChannelsProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 8),
        isEmpty: (channels) => channels.isEmpty,
        data: (context, channels) => _ChannelList(channels: channels),
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.channels});

  final List<LeadChannel> channels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final connected = channels.where((c) => c.isConnected);
    final total = connected.fold<int>(0, (sum, c) => sum + c.leadCount);
    final week = connected.fold<int>(0, (sum, c) => sum + c.leadsThisWeek);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(leadChannelsProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          SrNote(message: l10n.growthChannelsNote),
          const SizedBox(height: 12),
          SrStatGrid(
            columns: 2,
            tiles: [
              SrKpiTile(
                label: l10n.growthChannelsLeadsTotal,
                value: fmt.number(total),
              ),
              SrKpiTile(
                label: l10n.growthChannelsLeadsWeek,
                value: fmt.number(week),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SrRowGroup(
            rows: [
              for (final channel in channels) _ChannelRow(channel: channel),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends ConsumerWidget {
  const _ChannelRow({required this.channel});

  final LeadChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref
        .watch(moduleAccessProvider(AppModule.leadSources))
        .canEdit;
    final kind = channel.kind;
    final opensPage =
        kind == ChannelKind.facebook || kind == ChannelKind.messenger;
    final VoidCallback? onTap = switch (channel.status) {
      ChannelStatus.soon => null,
      _ when opensPage =>
        canEdit ? () => context.push(Routes.growthFacebook) : null,
      _ => () => showSrSheet<void>(
        context: context,
        builder: (_) => ChannelSheet(channel: channel),
      ),
    };
    return SrListRow(
      leading: SrAvatar(
        icon: kind.icon,
        tone: channel.isConnected ? SrAvatarTone.accent : SrAvatarTone.neutral,
      ),
      title: kind.label(l10n),
      subtitle: _subtitle(context),
      trailing: _tag(l10n),
      onTap: onTap,
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    if (channel.status == ChannelStatus.soon) return l10n.growthChannelSoonHint;
    final account = channel.account;
    final accountText = account == null
        ? ''
        : channel.kind == ChannelKind.whatsapp
        ? growthPhone(context, account)
        : account;
    if (!channel.isConnected) return accountText;
    return [
      if (accountText.isNotEmpty) accountText,
      if (channel.formCount > 0)
        l10n.growthChannelForms(fmt.number(channel.formCount)),
      if (channel.leadCount > 0)
        l10n.growthChannelLeads(fmt.number(channel.leadCount)),
      if (channel.kind == ChannelKind.messenger) l10n.growthChannelWithPage,
    ].join(' · ');
  }

  Widget _tag(AppLocalizations l10n) => switch (channel.status) {
    ChannelStatus.connected => SrTag(
      l10n.growthChannelConnected,
      tone: SrTone.ok,
    ),
    ChannelStatus.soon => SrTag(l10n.growthChannelSoon),
    ChannelStatus.available => SrTag(switch (channel.kind) {
      ChannelKind.website => l10n.growthChannelGetCode,
      ChannelKind.hostedForm => l10n.commonShare,
      _ => l10n.growthChannelConnect,
    }, tone: SrTone.accent),
  };
}
