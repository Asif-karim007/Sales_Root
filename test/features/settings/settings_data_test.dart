import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/features/settings/data/settings_repositories.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';

import '../../helpers/api_stub.dart';
import 'settings_test_setup.dart';

void main() {
  group('account', () {
    test('devices come from the account sessions', () async {
      final container = await settingsContainer(settingsStub());

      final devices = await container.read(devicesProvider.future);

      expect(devices, hasLength(3));
      expect(devices.last.name, 'agent-settings');
      expect(devices.last.kind, DeviceKind.android);
      expect(devices.last.appVersion, '1.0.0');
      expect(devices.last.lastActiveAt, isNotNull);
    });

    test('a failed device list is an error, not an empty list', () async {
      final stub = settingsStub()..fail('GET', 'auth/devices', 500);
      final container = await settingsContainer(stub);

      await expectLater(
        container.read(devicesProvider.future),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('signing out everywhere calls logout-all', () async {
      final stub = settingsStub()..on('POST', 'auth/logout-all', null);
      final container = await settingsContainer(stub);

      await container.read(settingsRepositoryProvider).signOutEverywhere();

      expect(stub.last('POST', 'auth/logout-all'), isNotNull);
    });

    test('the language is saved on the account', () async {
      final stub = settingsStub()..on('PATCH', 'auth/me', fixture('auth_me'));
      final container = await settingsContainer(stub);

      await container.read(settingsRepositoryProvider).saveLanguage('en');

      expect(stub.lastBody('PATCH', 'auth/me'), {'language': 'en'});
    });
  });

  group('notifications', () {
    test('choices are kept per workspace and survive a reload', () async {
      final container = await settingsContainer(settingsStub());
      listenTo(container, notificationPrefsProvider);

      expect(container.read(notificationPrefsProvider).quietEnabled, isTrue);
      container
          .read(notificationPrefsProvider.notifier)
          .save(
            container
                .read(notificationPrefsProvider)
                .toggle(NotificationTopic.chat, false)
                .copyWith(digestMinute: 8 * 60),
          );
      container.invalidate(notificationPrefsProvider);

      final prefs = container.read(notificationPrefsProvider);
      expect(prefs.isOn(NotificationTopic.chat), isFalse);
      expect(prefs.digestMinute, 8 * 60);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getKeys()
            .where((k) => k.startsWith('settings/notifications/')),
        hasLength(1),
      );
    });
  });

  group('pipelines', () {
    test('stages group under their pipeline in board order', () async {
      final container = await settingsContainer(settingsStub());

      final pipelines = await container.read(pipelinesProvider.future);

      expect(pipelines, hasLength(1));
      final sales = pipelines.single;
      expect(sales.id, pipelineId);
      expect(sales.isDefault, isTrue);
      expect(sales.stages.first.name.en, 'To contact');
      expect(sales.stages.first.name.bn, 'যোগাযোগ বাকি');
      expect(sales.stages.first.winPercent, 10);
      expect(sales.stages.first.showInEasy, isTrue);
      expect(sales.stages.last.kind, StageKind.lost);
      expect(
        sales.stages.firstWhere((s) => s.name.en == 'Ordered').kind,
        StageKind.won,
      );
      expect(sales.stages[2].requiredFields, ['productInterest']);
      expect(sales.openStages, hasLength(6));
    });

    test('adding a stage sends a StageRequest and reloads', () async {
      final stub = settingsStub()
        ..on('POST', 'workspaces/pipelines/{id}/stages', const {});
      final container = await settingsContainer(stub, role: 'owner');
      listenTo(container, pipelinesProvider);
      await container.read(pipelinesProvider.future);
      final loads = stub.requests
          .where((r) => r.path.endsWith('workspaces/pipelines'))
          .length;

      await container
          .read(pipelinesProvider.notifier)
          .addStage(
            pipelineId,
            const StageInput(
              nameEn: ' Negotiation ',
              nameBn: 'দরকষাকষি',
              winPercent: 70,
              showInEasy: false,
              universalStep: 5,
            ),
          );

      expect(
        stub.last('POST', 'workspaces/pipelines/{id}/stages')?.path,
        endsWith('$pipelineId/stages'),
      );
      expect(stub.lastBody('POST', 'workspaces/pipelines/{id}/stages'), {
        'nameEn': 'Negotiation',
        'nameBn': 'দরকষাকষি',
        'universalStep': 5,
        'showInEasy': false,
        'probability': 70,
        'requiredFields': <String>[],
      });
      expect(
        stub.requests
            .where((r) => r.path.endsWith('workspaces/pipelines'))
            .length,
        loads + 1,
      );
    });

    test('a refused stage edit shows the field message', () async {
      final stub = settingsStub()
        ..fail(
          'PATCH',
          'workspaces/stages/{id}',
          422,
          message: 'Name is required',
          field: 'nameEn',
        );
      final container = await settingsContainer(stub, role: 'owner');
      listenTo(container, pipelinesProvider);
      final stage = (await container.read(
        pipelinesProvider.future,
      )).single.stages.first;

      await expectLater(
        container
            .read(pipelinesProvider.notifier)
            .editStage(
              stage.id,
              const StageInput(
                nameEn: '',
                nameBn: '',
                winPercent: 10,
                showInEasy: true,
                universalStep: 1,
              ),
            ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.fieldErrors['nameEn'],
            'nameEn',
            'Name is required',
          ),
        ),
      );
    });

    test('moving a stage sends every stage in the new order', () async {
      final stub = settingsStub()
        ..on('POST', 'workspaces/stages/reorder', const {});
      final container = await settingsContainer(stub, role: 'owner');
      listenTo(container, pipelinesProvider);
      final before = (await container.read(pipelinesProvider.future)).single;

      await container
          .read(pipelinesProvider.notifier)
          .moveStage(pipelineId, 0, 1);

      final sent = stub.last('POST', 'workspaces/stages/reorder')?.data as List;
      final after = container.read(pipelinesProvider).value?.single;
      expect(sent, [for (final s in after?.stages ?? []) s.id]);
      expect(sent, hasLength(before.stages.length));
      expect(sent.take(2), [before.stages[1].id, before.stages[0].id]);
      expect(after?.stages[3].kind, StageKind.won);
    });

    test('a refused move puts the stages back', () async {
      final stub = settingsStub()
        ..fail('POST', 'workspaces/stages/reorder', 403);
      final container = await settingsContainer(stub);
      listenTo(container, pipelinesProvider);
      final before = (await container.read(pipelinesProvider.future)).single;

      await expectLater(
        container.read(pipelinesProvider.notifier).moveStage(pipelineId, 0, 2),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', isTrue)),
      );
      expect(
        container.read(pipelinesProvider).value?.single.stages.map((s) => s.id),
        before.stages.map((s) => s.id),
      );
    });
  });

  group('form fields', () {
    test('come from the industry pack, per form', () async {
      final container = await settingsContainer(settingsStub());

      final lead = await container.read(
        formFieldsProvider(FormKind.lead).future,
      );
      final company = await container.read(
        formFieldsProvider(FormKind.company).future,
      );

      expect(lead.single.key, 'productInterest');
      expect(lead.single.label.bn, 'কী পণ্য চান');
      expect(lead.single.type, FieldType.text);
      expect(company.map((f) => f.key), ['outletType', 'route', 'shopSize']);
      expect(company.first.type, FieldType.choice);
      expect(company.first.options, ['retail', 'wholesale', 'modern_trade']);
    });
  });
}
