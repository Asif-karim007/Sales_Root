import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/data/api_config_repository.dart';
import 'package:salesroot/features/settings/data/api_import_repository.dart';
import 'package:salesroot/features/settings/data/api_report_repository.dart';
import 'package:salesroot/features/settings/data/api_settings_repository.dart';
import 'package:salesroot/features/settings/data/api_sync_repository.dart';
import 'package:salesroot/features/settings/data/config_repository.dart';
import 'package:salesroot/features/settings/data/import_repository.dart';
import 'package:salesroot/features/settings/data/report_repository.dart';
import 'package:salesroot/features/settings/data/settings_api.dart';
import 'package:salesroot/features/settings/data/settings_repository.dart';
import 'package:salesroot/features/settings/data/sync_repository.dart';
import 'package:salesroot/features/settings/data/sync_store.dart';

part 'settings_repositories.g.dart';

@Riverpod(keepAlive: true)
SettingsApi settingsApi(Ref ref) => SettingsApi(ref.watch(dioProvider));

/// The API, rebuilding each repository on a workspace switch.
SettingsApi _api(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ref.watch(settingsApiProvider);
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    ApiSettingsRepository(ref.watch(settingsApiProvider));

@Riverpod(keepAlive: true)
ConfigRepository configRepository(Ref ref) => ApiConfigRepository(_api(ref));

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) => ApiImportRepository(_api(ref));

@Riverpod(keepAlive: true)
ReportRepository reportRepository(Ref ref) => ApiReportRepository(
  _api(ref),
  memberId: () => ref.read(currentWorkspaceProvider)?.membershipId,
  today: DateTime.now,
);

@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) {
  final workspaceId = ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiSyncRepository(
    ref.watch(settingsApiProvider),
    SyncStore(ref.watch(sharedPreferencesProvider), workspaceId ?? ''),
    bangla: () => ref.read(appLocaleProvider) == bangla,
  );
}
