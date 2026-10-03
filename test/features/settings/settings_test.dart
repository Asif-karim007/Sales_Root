import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';

import 'settings_test_utils.dart';

void main() {
  test('login history pages 20 at a time', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, loginHistoryProvider);

    final first = await container.read(loginHistoryProvider.future);
    expect(first.items, hasLength(20));
    expect(first.hasMore, isTrue);

    final notifier = container.read(loginHistoryProvider.notifier);
    await notifier.loadMore();
    await notifier.loadMore();
    final all = container.read(loginHistoryProvider).requireValue;

    expect(all.items, hasLength(46));
    expect(all.hasMore, isFalse);
    expect(all.items.map((e) => e.id).toSet(), hasLength(46));
  });

  test('a failed page keeps the rows and records the failure', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, loginHistoryProvider);
    await container.read(loginHistoryProvider.future);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: true));

    await container.read(loginHistoryProvider.notifier).loadMore();
    final page = container.read(loginHistoryProvider).requireValue;

    expect(page.items, hasLength(20));
    expect(page.loadMoreError?.isOffline, isTrue);
  });

  test('notification choices are saved and survive a reload', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, notificationPrefsProvider);
    final prefs = await container.read(notificationPrefsProvider.future);
    expect(prefs.isOn(NotificationTopic.chat), isTrue);

    await container
        .read(notificationPrefsProvider.notifier)
        .save(
          prefs
              .toggle(NotificationTopic.chat, false)
              .copyWith(digestMinute: 480),
        );
    container.invalidate(notificationPrefsProvider);
    final reloaded = await container.read(notificationPrefsProvider.future);

    expect(reloaded.isOn(NotificationTopic.chat), isFalse);
    expect(reloaded.digestMinute, 480);
  });

  test('a refused notification change rolls back', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, notificationPrefsProvider);
    final prefs = await container.read(notificationPrefsProvider.future);

    await expectLater(
      container
          .read(notificationPrefsProvider.notifier)
          .save(prefs.copyWith(quietFromMinute: 600, quietToMinute: 600)),
      throwsA(isA<ApiFailure>()),
    );
    expect(
      container.read(notificationPrefsProvider).requireValue.quietToMinute,
      prefs.quietToMinute,
    );
  });

  test('devices: remove one, then sign out the rest', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, devicesProvider);
    final devices = await container.read(devicesProvider.future);
    expect(devices, hasLength(3));

    final notifier = container.read(devicesProvider.notifier);
    await notifier.remove(devices[1].id);
    expect(container.read(devicesProvider).requireValue, hasLength(2));
    await notifier.signOutOthers();

    expect(
      container.read(devicesProvider).requireValue.single.isCurrent,
      isTrue,
    );
  });

  test('the owner renames and reorders stages', () async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);
    keepAlive(container, pipelinesProvider);
    final sales = (await container.read(pipelinesProvider.future)).first;
    final first = sales.openStages.first;
    final notifier = container.read(pipelinesProvider.notifier);

    await notifier.editStage(
      sales.id,
      first.id,
      StageInput(
        name: 'New lead',
        nameBn: 'নতুন লিড',
        winPercent: 15,
        minLevel: first.minLevel,
      ),
    );
    await notifier.moveStage(sales.id, 0, 2);
    final updated = container.read(pipelinesProvider).requireValue.first;

    expect(updated.openStages[2].id, first.id);
    expect(updated.openStages[2].name.bn, 'নতুন লিড');
    expect(updated.openStages[2].winPercent, 15);
    expect(updated.stages.last.kind, StageKind.lost);
  });

  test('Easy mode is capped at four stages', () async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);
    keepAlive(container, pipelinesProvider);
    final sales = (await container.read(pipelinesProvider.future)).first;
    final notifier = container.read(pipelinesProvider.notifier);
    StageInput easy(String name) => StageInput(
      name: name,
      nameBn: name,
      winPercent: 50,
      minLevel: ExperienceLevel.easy,
    );

    await notifier.addStage(sales.id, easy('Site survey'));
    await expectLater(
      notifier.addStage(sales.id, easy('Negotiation')),
      throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 400)),
    );
    await expectLater(
      notifier.addStage(sales.id, easy('site survey')),
      throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 409)),
    );
  });

  test('a team lead may look at stages but not change them', () async {
    final container = await signedInContainer(role: WorkspaceRole.teamLead);
    addTearDown(container.dispose);
    keepAlive(container, pipelinesProvider);
    final sales = (await container.read(pipelinesProvider.future)).first;

    await expectLater(
      container.read(pipelinesProvider.notifier).moveStage(sales.id, 0, 1),
      throwsA(
        isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', true),
      ),
    );
    expect(
      container.read(pipelinesProvider).requireValue.first.openStages.first.id,
      sales.openStages.first.id,
    );
  });

  test('a required field has to show at every level', () async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);
    final provider = formFieldsProvider(FormKind.lead);
    keepAlive(container, provider);
    final fields = await container.read(provider.future);
    final value = fields.firstWhere((f) => f.label.en == 'Deal value');

    await expectLater(
      container
          .read(provider.notifier)
          .save(value.id, FormFieldInput(required: true, levels: value.levels)),
      throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 400)),
    );
    await container
        .read(provider.notifier)
        .save(
          value.id,
          const FormFieldInput(
            required: true,
            levels: {
              ExperienceLevel.easy,
              ExperienceLevel.standard,
              ExperienceLevel.advanced,
            },
          ),
        );

    final saved = container
        .read(provider)
        .requireValue
        .firstWhere((f) => f.id == value.id);
    expect(saved.required, isTrue);
    expect(saved.levels, hasLength(3));
  });
}
