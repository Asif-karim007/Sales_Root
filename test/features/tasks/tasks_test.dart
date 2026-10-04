import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/tasks/data/fake_card_scan_repository.dart';
import 'package:salesroot/features/tasks/models/calendar_event.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/providers/calendar_providers.dart';
import 'package:salesroot/features/tasks/providers/scan_providers.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/calendar_screen.dart';
import 'package:salesroot/features/tasks/view/private_event_screen.dart';
import 'package:salesroot/features/tasks/view/qr_result_screen.dart';
import 'package:salesroot/features/tasks/view/scan_capture_screen.dart';
import 'package:salesroot/features/tasks/view/scan_lead_screen.dart';
import 'package:salesroot/features/tasks/view/scan_review_screen.dart';
import 'package:salesroot/features/tasks/view/task_detail_screen.dart';
import 'package:salesroot/features/tasks/view/task_form_screen.dart';
import 'package:salesroot/features/tasks/view/tasks_screen.dart';
import 'package:salesroot/translations/translations.dart';

void main() {
  group('task tabs', () {
    test('Today holds what is late, due today and due tomorrow', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);

      var paged = await container.read(taskListProvider.future);
      while (paged.hasMore) {
        await container.read(taskListProvider.notifier).loadMore();
        paged = container.read(taskListProvider).requireValue;
      }
      final days = {for (final t in paged.items) t.daysUntilDue};

      expect(paged.items, isNotEmpty);
      expect(
        paged.items.every(
          (t) => t.isOverdue || t.daysUntilDue == 0 || t.daysUntilDue == 1,
        ),
        isTrue,
      );
      expect(days, containsAll([0, 1]));
      expect(paged.items.map((t) => t.title), contains('Call Karim Textiles'));
      expect(paged.items.every((t) => t.assignedToMe), isTrue);
    });

    test('each tab filters, and the counts agree with the tabs', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final counts = await container.read(taskCountsProvider.future);

      for (final bucket in TaskBucket.values.skip(1)) {
        container.read(taskBucketProvider.notifier).show(bucket);
        final paged = await container.read(taskListProvider.future);
        expect(paged.totalCount, counts.of(bucket), reason: bucket.wire);
        final ok = switch (bucket) {
          TaskBucket.overdue => paged.items.every((t) => t.isOverdue),
          TaskBucket.week => paged.items.every(
            (t) => !t.isDone && (t.daysUntilDue ?? -1) >= 0,
          ),
          TaskBucket.all => paged.items.every((t) => !t.isDone),
          TaskBucket.done => paged.items.every((t) => t.isDone),
          TaskBucket.today => true,
        };
        expect(ok, isTrue, reason: bucket.wire);
      }
      expect(counts.overdue, greaterThan(0));
      expect(counts.done, greaterThan(0));
    });

    test('the team view pages 20 at a time', () async {
      final container = await tasksContainer(role: WorkspaceRole.owner);
      addTearDown(container.dispose);
      container
          .read(taskFilterProvider.notifier)
          .apply(const TaskFilter(who: TaskWho.everyone));
      container.read(taskBucketProvider.notifier).show(TaskBucket.all);

      final first = await container.read(taskListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      await container.read(taskListProvider.notifier).loadMore();
      final second = container.read(taskListProvider).requireValue;
      expect(second.items, hasLength(40));
      expect(second.items.map((t) => t.id).toSet(), hasLength(40));
    });

    test('offline shows as a failure with status 0', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      setDev(container, (s) => s.copyWith(offline: true));
      final sub = container.listen(taskListProvider, (_, _) {});
      addTearDown(sub.close);

      await expectLater(
        container.read(taskListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('complete with undo', () {
    test('ticks off in place, then undo reopens it', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final before = await container.read(taskCountsProvider.future);
      final paged = await container.read(taskListProvider.future);
      final task = paged.items.firstWhere(
        (t) => !t.isDone && t.daysUntilDue == 0,
      );
      final notifier = container.read(taskListProvider.notifier);

      final done = await notifier.setDone(task, done: true);
      expect(done.isDone, isTrue);
      expect(done.completedOn, isNotNull);
      final row = container
          .read(taskListProvider)
          .requireValue
          .items
          .firstWhere((t) => t.id == task.id);
      expect(row.isDone, isTrue);
      final after = await container.read(taskCountsProvider.future);
      expect(after.today, before.today - 1);
      expect(after.done, before.done + 1);

      final undone = await notifier.setDone(done, done: false);
      expect(undone.isDone, isFalse);
      final restored = await container.read(taskCountsProvider.future);
      expect(restored.today, before.today);
      expect(restored.done, before.done);
    });

    test('a failed tick puts the row back and rethrows', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final paged = await container.read(taskListProvider.future);
      final task = paged.items.firstWhere((t) => !t.isDone);
      final notifier = container.read(taskListProvider.notifier);
      setDev(container, (s) => s.copyWith(offline: true));

      await expectLater(
        notifier.setDone(task, done: true),
        throwsA(isA<ApiFailure>()),
      );
      final row = container
          .read(taskListProvider)
          .value
          ?.items
          .firstWhere((t) => t.id == task.id);
      expect(row?.isDone, isFalse);
    });
  });

  group('new task', () {
    test('a prefilled leadId links the lead and saves', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final provider = taskFormProvider(leadId: 3, title: 'Call Meghna Group');
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      final draft = await container.read(provider.future);
      expect(draft.lead?.id, 3);
      expect(draft.title, 'Call Meghna Group');
      expect(draft.isEdit, isFalse);

      await container.read(provider.notifier).save();
      final saved = container.read(provider).requireValue.saved;
      expect(saved, isNotNull);
      expect(saved?.lead?.id, 3);
      expect(saved?.assignedToMe, isTrue);
      expect(saved?.lead?.contactName, isNotNull);

      final fetched = await container.read(taskProvider(saved?.id ?? 0).future);
      expect(fetched.title, 'Call Meghna Group');
    });

    test('a blank title is a 400 on the Title field', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final provider = taskFormProvider();
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);

      await container.read(provider.notifier).save();
      final failure = container.read(provider).requireValue.failure;
      expect(failure?.isValidation, isTrue);
      expect(failure?.fieldError('Title'), isNotNull);
    });

    test('a member may not reassign', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final paged = await container.read(taskListProvider.future);

      await expectLater(
        container
            .read(taskEditorProvider.notifier)
            .reassign(paged.items.first.id, 3),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
    });
  });

  group('calendar', () {
    test('merges tasks and private events by day, in time order', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final today = AppDateUtils.dateOnly(DateTime.now());
      final from = DateTime(today.year, today.month, today.day - 3);
      final to = DateTime(today.year, today.month, today.day + 4);

      final agenda = await container.read(
        calendarAgendaProvider(from, to).future,
      );
      final items = agenda.on(today);

      expect(items.whereType<TaskAgendaItem>(), isNotEmpty);
      expect(
        items.whereType<EventAgendaItem>().map((e) => e.event.title),
        contains('Doctor appointment'),
      );
      for (var i = 1; i < items.length; i++) {
        expect(items[i].at.isBefore(items[i - 1].at), isFalse);
      }
      expect(
        items.whereType<TaskAgendaItem>().every((i) => i.task.assignedToMe),
        isTrue,
      );
    });

    test('a saved private event shows on its day', () async {
      final container = await tasksContainer();
      addTearDown(container.dispose);
      final day = DateTime(2026, 11, 3);
      final provider = eventFormProvider(day: day);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);

      container.read(provider.notifier).setTitle('Dentist');
      await container.read(provider.notifier).save();

      final agenda = await container.read(
        calendarAgendaProvider(DateTime(2026, 11), DateTime(2026, 12)).future,
      );
      expect(
        agenda.on(day).whereType<EventAgendaItem>().map((e) => e.event.title),
        ['Dentist'],
      );
    });

    test('weeks start on Saturday', () {
      final cursor = CalendarCursor(
        month: DateTime(2026, 10),
        selected: DateTime(2026, 10, 1),
      );
      expect(cursor.weekStart, DateTime(2026, 9, 26));
      expect(cursor.weekStart.weekday, DateTime.saturday);
      expect(cursor.weekEnd, DateTime(2026, 10, 3));
    });
  });

  final photo = Uint8List.fromList(List.filled(64, 7));

  test('without a Gemini key the fake reader is used', () async {
    final container = await tasksContainer();
    addTearDown(container.dispose);
    expect(
      container.read(cardScanRepositoryProvider),
      isA<FakeCardScanRepository>(),
    );
  });

  test('the fake reader returns parsed cards in turn', () async {
    final container = await tasksContainer();
    addTearDown(container.dispose);
    final reader = container.read(cardScanRepositoryProvider);

    final first = await reader.scan(photo);
    final second = await reader.scan(photo);

    final card = (first as CardScanResult).card;
    expect(card.contactName, 'Md. Karim');
    expect(card.companyName, 'Karim Textiles Ltd.');
    expect(card.phone, '+880 1711-234567');
    expect(card.email, 'karim@karimtex.com');
    expect(card.filledCount, 6);
    expect(card.unsure, isEmpty);

    final unsure = (second as CardScanResult).card;
    expect(unsure.unsure, {CardField.email});
    expect(unsure.phones, hasLength(2));
  });

  test('QR mode reads a link, then a vCard as a contact', () async {
    final container = await tasksContainer();
    addTearDown(container.dispose);
    final reader = container.read(cardScanRepositoryProvider);

    final link = await reader.scan(photo, mode: ScanMode.qr);
    expect(link, isA<QrScanResult>());
    expect(
      (link as QrScanResult).link,
      Uri.parse('https://karimtex.com/catalog/2026'),
    );

    final vcard = await reader.scan(photo, mode: ScanMode.qr);
    final card = (vcard as CardScanResult).card;
    expect(card.contactName, 'Rezaul Karim');
    expect(card.companyName, 'Meghna Group');
    expect(card.designation, 'Accounts Manager');
    expect(card.phone, '+8801715667788');
  });

  test('MECARD and plain text QR codes', () {
    final me = QrScanResult.parse(
      'MECARD:N:Hossain,Sajib;TEL:+8801812345678;EMAIL:sajib@delta.com;'
      'ORG:Delta Power;;',
    );
    final card = (me as CardScanResult).card;
    expect(card.contactName, 'Sajib Hossain');
    expect(card.companyName, 'Delta Power');
    expect(card.email, 'sajib@delta.com');

    final text = QrScanResult.parse('WIFI:T:WPA;S:Office;P:x;;');
    expect(text, isA<QrScanResult>());
    expect((text as QrScanResult).link, isNull);
  });

  test('a scan past the plan limit is a 402 on card scans', () async {
    final container = await tasksContainer();
    addTearDown(container.dispose);
    setDev(container, (s) => s.copyWith(quotaReached: true));
    await container.read(scanSessionProvider.future);

    await container
        .read(scanSessionProvider.notifier)
        .scan(photo, ScanMode.card);

    final state = container.read(scanSessionProvider);
    expect(state.hasError, isTrue);
    final failure = state.error;
    expect(failure, isA<ApiFailure>());
    expect((failure as ApiFailure).isQuota, isTrue);
    expect(failure.quota, QuotaKind.cardScans);
  });

  test('a successful scan is kept for the review, with edits', () async {
    final container = await tasksContainer();
    addTearDown(container.dispose);
    await container.read(scanSessionProvider.future);
    final session = container.read(scanSessionProvider.notifier);

    await session.scan(photo, ScanMode.card);
    final card = container.read(scanSessionProvider).requireValue?.card;
    expect(card?.contactName, 'Md. Karim');

    session.edit(
      card?.edited({CardField.contactName: 'Mohammad Karim'}) ??
          const ScannedCard(),
    );
    expect(
      container.read(scanSessionProvider).requireValue?.card?.contactName,
      'Mohammad Karim',
    );
  });

  group('screens render', () {
    Future<void> pump(
      WidgetTester tester,
      ProviderContainer container,
      Widget screen,
      Locale locale,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: screen,
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    final screens = <String, (Widget, String?)>{
      'tasks': (const TasksScreen(), 'This week'),
      'task detail': (const TaskDetailScreen(id: 3), 'Mark done'),
      'new task': (const TaskFormScreen(leadId: 1), 'Karim Textiles (lead)'),
      'edit task': (const TaskFormScreen(taskId: 3), 'Edit task'),
      'calendar': (const CalendarScreen(), 'Doctor appointment'),
      'private event': (const PrivateEventScreen(), 'Private event'),
      'scan capture': (const ScanCaptureScreen(), 'Scan a card'),
      'scan review': (const ScanReviewScreen(), 'No card scanned'),
      'scan lead': (const ScanLeadScreen(), 'No card scanned'),
      'qr result': (const QrResultScreen(), 'No QR code scanned'),
    };

    for (final locale in [english, bangla]) {
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets('$name in ${locale.languageCode}', (tester) async {
          final container = await tasksContainer(
            role: WorkspaceRole.owner,
            fullAccess: true,
          );
          addTearDown(container.dispose);

          await pump(tester, container, screen, locale);

          expect(tester.takeException(), isNull);
          if (locale == english && text != null) {
            expect(find.textContaining(text), findsWidgets);
          }
        });
      }
    }
  });
}

/// A container over the fake backend for a 25-person team workspace, with
/// latency off and the given [role].
Future<ProviderContainer> tasksContainer({
  WorkspaceRole role = WorkspaceRole.member,
  bool fullAccess = false,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedGraphProvider.overrideWithValue(
        SeedGraph.build(
          workspaceId: 7,
          kind: WorkspaceKind.team,
          memberCount: 25,
          leadCount: 230,
        ),
      ),
      if (fullAccess)
        moduleAccessProvider.overrideWith(
          (ref, module) => const ModuleAccess(
            canView: true,
            canAdd: true,
            canEdit: true,
            canDelete: true,
            canApprove: true,
            canExport: true,
          ),
        ),
    ],
  );
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false, role: () => role));
  return container;
}

void setDev(
  ProviderContainer container,
  DevSettings Function(DevSettings settings) change,
) => container.read(devSettingsProvider.notifier).update(change);
