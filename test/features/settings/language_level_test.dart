import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';

import 'settings_test_utils.dart';

void main() {
  test('switching language persists it', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    expect(container.read(appLocaleProvider), bangla);
    container.read(appLocaleProvider.notifier).set(english);

    expect(container.read(appLocaleProvider), english);
    expect(
      container.read(sharedPreferencesProvider).getString('language'),
      'en',
    );
  });

  test('moving to Advanced opens the workspace setup screens', () async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);

    expect(
      container.read(moduleAccessProvider(AppModule.pipelines)).visible,
      isFalse,
    );
    container
        .read(experienceLevelProvider.notifier)
        .set(ExperienceLevel.advanced);

    expect(container.read(experienceLevelProvider), ExperienceLevel.advanced);
    expect(
      container.read(moduleAccessProvider(AppModule.pipelines)).visible,
      isTrue,
    );
    expect(
      container.read(moduleAccessProvider(AppModule.formFields)).canEdit,
      isTrue,
    );
  });

  test('a locked level ignores changes and names the owner', () async {
    final container = await signedInContainer(lockLevel: true);
    addTearDown(container.dispose);

    final before = container.read(experienceLevelProvider);
    container
        .read(experienceLevelProvider.notifier)
        .set(ExperienceLevel.advanced);

    expect(container.read(experienceLevelLockedProvider), isTrue);
    expect(container.read(experienceLevelProvider), before);
    expect(
      container.read(currentWorkspaceProvider)?.ownerName,
      'Mohammad Kamal',
    );
  });

  test('read aloud is remembered on the phone', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    container.read(devicePrefsProvider.notifier).setReadAloud(true);

    expect(container.read(devicePrefsProvider).readAloud, isTrue);
    expect(
      container.read(sharedPreferencesProvider).getBool('settings/read_aloud'),
      isTrue,
    );
  });
}
