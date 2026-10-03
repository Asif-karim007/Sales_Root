import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #87: which notifications to get, the daily digest and quiet hours.
class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.settingsNotifications,
        actions: const [LanguageAction()],
      ),
      body: SrAsyncView(
        value: prefs,
        onRetry: () => ref.invalidate(notificationPrefsProvider),
        data: (context, prefs) => ListView(
          padding: screenPadding,
          children: [
            _TopicsGroup(prefs: prefs),
            const SizedBox(height: 18),
            _TimingGroup(prefs: prefs),
          ],
        ),
      ),
    );
  }
}

Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  NotificationPrefs next,
) async {
  try {
    await ref.read(notificationPrefsProvider.notifier).save(next);
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    showSrError(context, failure.message);
  }
}

class _TopicsGroup extends ConsumerWidget {
  const _TopicsGroup({required this.prefs});

  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final topics = [
      for (final topic in NotificationTopic.values)
        if (_visible(ref, topic)) topic,
    ];
    return SrRowGroup(
      rows: [
        for (final topic in topics)
          ToggleRow(
            title: _title(l10n, topic),
            subtitle: _hint(l10n, topic),
            value: prefs.isOn(topic),
            onChanged: (on) => _save(context, ref, prefs.toggle(topic, on)),
          ),
      ],
    );
  }

  static bool _visible(WidgetRef ref, NotificationTopic topic) {
    final module = topic.module;
    return module == null || ref.watch(moduleAccessProvider(module)).visible;
  }

  static String _title(AppLocalizations l10n, NotificationTopic topic) =>
      switch (topic) {
        NotificationTopic.reminders => l10n.settingsNotifReminders,
        NotificationTopic.assignments => l10n.settingsNotifAssignments,
        NotificationTopic.chat => l10n.settingsNotifChat,
        NotificationTopic.newLeads => l10n.settingsNotifNewLeads,
        NotificationTopic.inbox => l10n.settingsNotifInbox,
        NotificationTopic.approvals => l10n.settingsNotifApprovals,
        NotificationTopic.notices => l10n.settingsNotifNotices,
        NotificationTopic.billing => l10n.settingsNotifBilling,
        NotificationTopic.academy => l10n.settingsNotifAcademy,
      };

  static String _hint(AppLocalizations l10n, NotificationTopic topic) =>
      switch (topic) {
        NotificationTopic.reminders => l10n.settingsNotifRemindersHint,
        NotificationTopic.assignments => l10n.settingsNotifAssignmentsHint,
        NotificationTopic.chat => l10n.settingsNotifChatHint,
        NotificationTopic.newLeads => l10n.settingsNotifNewLeadsHint,
        NotificationTopic.inbox => l10n.settingsNotifInboxHint,
        NotificationTopic.approvals => l10n.settingsNotifApprovalsHint,
        NotificationTopic.notices => l10n.settingsNotifNoticesHint,
        NotificationTopic.billing => l10n.settingsNotifBillingHint,
        NotificationTopic.academy => l10n.settingsNotifAcademyHint,
      };
}

class _TimingGroup extends ConsumerWidget {
  const _TimingGroup({required this.prefs});

  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    String at(int minute) => fmt.time(DateTime(2000, 1, 1, 0, minute));
    return SrRowGroup(
      title: l10n.settingsNotifTiming,
      rows: [
        SrListRow(
          title: l10n.settingsNotifDigest,
          subtitle: at(prefs.digestMinute),
          leading: const RowIcon(Icons.wb_sunny_outlined),
          chevron: true,
          onTap: () => _pick(
            context,
            ref,
            l10n.settingsNotifDigest,
            prefs.digestMinute,
            (m) => prefs.copyWith(digestMinute: m),
          ),
        ),
        ToggleRow(
          title: l10n.settingsNotifQuiet,
          subtitle: l10n.settingsNotifQuietRange(
            at(prefs.quietFromMinute),
            at(prefs.quietToMinute),
          ),
          leading: const RowIcon(Icons.bedtime_outlined),
          value: prefs.quietEnabled,
          onChanged: (on) =>
              _save(context, ref, prefs.copyWith(quietEnabled: on)),
        ),
        if (prefs.quietEnabled) ...[
          SrListRow(
            title: l10n.settingsNotifQuietFrom,
            trailing: SrRowTrailing(value: at(prefs.quietFromMinute)),
            chevron: true,
            onTap: () => _pick(
              context,
              ref,
              l10n.settingsNotifQuietFrom,
              prefs.quietFromMinute,
              (m) => prefs.copyWith(quietFromMinute: m),
            ),
          ),
          SrListRow(
            title: l10n.settingsNotifQuietTo,
            trailing: SrRowTrailing(value: at(prefs.quietToMinute)),
            chevron: true,
            onTap: () => _pick(
              context,
              ref,
              l10n.settingsNotifQuietTo,
              prefs.quietToMinute,
              (m) => prefs.copyWith(quietToMinute: m),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    String title,
    int current,
    NotificationPrefs Function(int minute) apply,
  ) async {
    final fmt = context.fmt;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: title,
        options: [for (var hour = 0; hour < 24; hour++) hour * 60],
        labelOf: (m) => fmt.time(DateTime(2000, 1, 1, 0, m)),
        isSelected: (m) => m == current,
      ),
    );
    if (picked == null || picked == current || !context.mounted) return;
    await _save(context, ref, apply(picked));
  }
}
