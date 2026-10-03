import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/features/settings/view/widget/sync_rows.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #92: what is waiting on the phone, conflicts, what stays offline and the
/// space it takes.
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _syncing = false;
  bool _offline = false;

  Future<void> _syncNow() async {
    if (_syncing) return;
    final l10n = context.l10n;
    setState(() => _syncing = true);
    try {
      await ref.read(syncProvider.notifier).syncNow();
      if (!mounted) return;
      setState(() => _offline = false);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _offline = failure.isOffline);
      showSrError(
        context,
        failure.isOffline ? l10n.settingsSyncOfflineHint : failure.message,
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(connectivityProvider, (previous, next) {
      final was = previous?.value ?? const <ConnectivityResult>[];
      final now = next.value ?? const <ConnectivityResult>[];
      if (_isOffline(was) && !_isOffline(now)) _syncNow();
    });
    final snapshot = ref.watch(syncProvider);
    final links = ref.watch(connectivityProvider).value;
    final offline = _offline || (links != null && _isOffline(links));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsSyncTitle,
        actions: const [LanguageAction()],
      ),
      body: SrAsyncView(
        value: snapshot,
        onRetry: () => ref.invalidate(syncProvider),
        data: (context, data) => RefreshIndicator(
          onRefresh: _syncNow,
          child: ListView(
            padding: screenPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SyncStatusCard(
                snapshot: data,
                offline: offline,
                network: _network(l10n, links),
                syncing: _syncing,
                onSync: _syncNow,
              ),
              const SizedBox(height: 12),
              SrStatGrid(
                columns: 2,
                tiles: [
                  SrKpiTile(
                    label: l10n.settingsSyncPending,
                    value: context.fmt.number(data.pendingCount),
                  ),
                  SrKpiTile(
                    label: l10n.settingsSyncConflicts,
                    value: context.fmt.number(data.conflicts.length),
                  ),
                ],
              ),
              if (data.conflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                ConflictList(conflicts: data.conflicts),
              ],
              if (data.outbox.isNotEmpty) ...[
                const SizedBox(height: 18),
                OutboxList(items: data.outbox, onRetry: _syncNow),
              ],
              if (data.history.isNotEmpty) ...[
                const SizedBox(height: 18),
                ResolvedList(history: data.history),
              ],
              const SizedBox(height: 18),
              const _OfflineGroup(),
              const SizedBox(height: 18),
              _StorageGroup(snapshot: data),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isOffline(List<ConnectivityResult> links) =>
      links.isEmpty || links.every((l) => l == ConnectivityResult.none);

  static String? _network(
    AppLocalizations l10n,
    List<ConnectivityResult>? links,
  ) {
    if (links == null || _isOffline(links)) return null;
    return links.contains(ConnectivityResult.wifi)
        ? l10n.settingsNetWifi
        : links.contains(ConnectivityResult.mobile)
        ? l10n.settingsNetMobile
        : links.contains(ConnectivityResult.ethernet)
        ? l10n.settingsNetEthernet
        : l10n.settingsNetOther;
  }
}

class _OfflineGroup extends ConsumerWidget {
  const _OfflineGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(syncPrefsProvider);
    final notifier = ref.read(syncPrefsProvider.notifier);
    return SrRowGroup(
      title: l10n.settingsSyncKept,
      rows: [
        SrListRow(
          title: l10n.settingsSyncHistory,
          subtitle: _days(context, prefs.historyDays),
          leading: const RowIcon(Icons.history_rounded),
          chevron: true,
          onTap: () async {
            final picked = await showSrSheet<int>(
              context: context,
              builder: (_) => SrOptionSheet<int>(
                title: l10n.settingsSyncHistory,
                options: SyncPrefs.historyChoices,
                labelOf: (days) => _days(context, days),
                isSelected: (days) => days == prefs.historyDays,
              ),
            );
            if (picked != null) notifier.setHistoryDays(picked);
          },
        ),
        ToggleRow(
          title: l10n.settingsSyncMedia,
          subtitle: l10n.settingsSyncMediaHint,
          leading: const RowIcon(Icons.photo_library_outlined),
          value: prefs.offlineMedia,
          onChanged: notifier.setOfflineMedia,
        ),
        ToggleRow(
          title: l10n.settingsSyncWifi,
          subtitle: l10n.settingsSyncWifiHint,
          leading: const RowIcon(Icons.wifi_rounded),
          value: prefs.mediaOnWifiOnly,
          onChanged: notifier.setMediaOnWifiOnly,
        ),
      ],
    );
  }

  static String _days(BuildContext context, int days) =>
      context.l10n.settingsSyncHistoryDays(context.fmt.number(days));
}

class _StorageGroup extends ConsumerWidget {
  const _StorageGroup({required this.snapshot});

  final SyncSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(
          title: l10n.settingsSyncStorage,
          rows: [
            FactLine(
              label: l10n.settingsSyncData,
              value: megabytes(context, snapshot.dataBytes),
            ),
            FactLine(
              label: l10n.settingsSyncCache,
              value: megabytes(context, snapshot.cacheBytes),
            ),
            if (version != null)
              FactLine(
                label: l10n.settingsSyncVersion,
                value: context.fmt.digits(version),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SrButton(
          label: l10n.settingsSyncClearCache,
          icon: Icons.cleaning_services_outlined,
          variant: SrButtonVariant.secondary,
          expand: true,
          onPressed: snapshot.cacheBytes == 0
              ? null
              : () => _clear(context, ref),
        ),
      ],
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showSrConfirm(
      context,
      title: l10n.settingsSyncClearTitle,
      message: l10n.settingsSyncClearBody,
      confirmLabel: l10n.settingsSyncClearCache,
      icon: Icons.cleaning_services_outlined,
    );
    if (!ok || !context.mounted) return;
    await ref.read(syncProvider.notifier).clearCache();
    if (!context.mounted) return;
    showSrSuccess(context, l10n.settingsSyncCleared);
  }
}
