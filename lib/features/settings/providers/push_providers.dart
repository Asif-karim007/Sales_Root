import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/firebase/push_messages.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/storage/install_id.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/data/settings_repositories.dart';
import 'package:salesroot/translations/translations.dart';

part 'push_providers.g.dart';

const _askedKey = 'push/permission_asked';

/// Asks once for permission to notify, then keeps this install's push token
/// registered for the signed-in user and workspace.
@Riverpod(keepAlive: true)
Future<void> pushRegistration(Ref ref) async {
  final userId = ref.watch(sessionProvider.select((s) => s.value?.userId));
  final workspaceId = ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  final push = ref.watch(pushMessagesProvider);
  if (userId == null || workspaceId == null || !push.available) return;
  final l10n = lookupAppLocalizations(ref.watch(appLocaleProvider));
  final prefs = ref.read(sharedPreferencesProvider);
  final repository = ref.read(settingsRepositoryProvider);

  Future<void> register(String token) => repository.registerPushToken(
    token,
    platform: push.platform,
    deviceId: installId(prefs),
  );

  final refreshed = push.tokenRefresh.listen(
    (token) => register(
      token,
    ).catchError((Object e) => logDebug('Push token refresh failed: $e')),
  );
  ref.onDispose(refreshed.cancel);

  await push.showWhileOpen(l10n.settingsPushChannel);
  if (prefs.getBool(_askedKey) != true) {
    await prefs.setBool(_askedKey, true);
    await push.requestPermission();
  }
  final token = await push.token();
  if (token != null) await register(token);
}
