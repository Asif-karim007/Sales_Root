import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/tasks/data/card_scan_repository.dart';
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

import '../../helpers/api_stub.dart';

const meId = '01a10101-8656-7886-b8e5-4f197fbd9159';
const bushraId = '01a10101-8656-7ec4-8e2a-2f921b517ab4';
const leadId = '01a10101-866a-7007-90bc-2326bcdb9d50';

void main() {
  group('task list', () {
    test('parses the recorded list and asks for my Today tab', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      listenTo(container, taskListProvider);

      final paged = await container.read(taskListProvider.future);

      expect(paged.items.map((t) => t.title), [
        'Visit Rahim Traders',
        'Call back Sumaiya about quote',
        'Collect ৳ 50,000 from Green Agro',
      ]);
      final visit = paged.items.first;
      expect(visit.type, TaskType.visit);
      expect(visit.assignedToMe, isTrue);
      expect(visit.assignedTo?.name, 'Rafi Ahmed');
      expect(visit.lead?.id, leadId);
      expect(visit.lead?.name, 'Mr Rahim');
      expect(visit.lead?.phone, '+8801811000010');
      expect(visit.companyName, 'Rahim Traders');
      expect(visit.reminderMinutes, 15);
      expect(paged.items[1].party, 'Sumaiya Akter');
      expect(paged.items[1].contactPhone, '+8801911000020');
      expect(paged.items[2].type, TaskType.collection);

      final query = stub.last('GET', 'tasks')?.queryParameters;
      expect(query?['view'], 'today');
      expect(query?['offset'], 0);
      expect(query?['limit'], 20);
      expect(query?['assignee'], meId);
    });

    test('overdue and the day count come from the local date', () {
      final row = rows().first;
      final sameDay = Task.fromJson(row, now: DateTime(2026, 10, 3, 23));
      final later = Task.fromJson(row, now: DateTime(2026, 10, 5, 9));
      final done = Task.fromJson(fixtureMap('tasks_done'));

      expect(sameDay.daysUntilDue, 0);
      expect(sameDay.isOverdue, isFalse);
      expect(later.daysUntilDue, -2);
      expect(later.isOverdue, isTrue);
      expect(done.isDone, isTrue);
      expect(done.isOverdue, isFalse);
      expect(done.completedOn, isNotNull);
      expect(done.notes, 'Bring the price list');
    });

    test('each tab sends its view', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      listenTo(container, taskListProvider);
      final now = DateTime.now();
      final weekEnd = AppDateUtils.toApiDateOnly(
        DateTime(now.year, now.month, now.day + 7),
      );

      for (final (bucket, view) in [
        (TaskBucket.overdue, 'overdue'),
        (TaskBucket.week, 'upcoming'),
        (TaskBucket.all, null),
        (TaskBucket.done, 'done'),
      ]) {
        container.read(taskBucketProvider.notifier).show(bucket);
        await container.read(taskListProvider.future);
        final query = stub.last('GET', 'tasks')?.queryParameters;
        expect(query?['view'], view, reason: bucket.name);
        expect(
          query?['to'],
          bucket == TaskBucket.week ? weekEnd : null,
          reason: bucket.name,
        );
      }
    });

    test('the counts are each tab\'s total', () async {
      const totals = {'today': 5, 'overdue': 3, 'upcoming': 4, 'done': 1};
      final stub = taskStub()
        ..on(
          'GET',
          'tasks',
          (RequestOptions r) => {
            'items': [rows().first],
            'total': totals[r.queryParameters['view']] ?? 10,
            'offset': 0,
            'limit': 1,
          },
        );
      final container = await tasksContainer(stub);
      listenTo(container, taskCountsProvider);

      final counts = await container.read(taskCountsProvider.future);

      expect(counts.today, 5);
      expect(counts.overdue, 3);
      expect(counts.week, 4);
      expect(counts.all, 10);
      expect(counts.done, 1);
      expect(
        stub.requests
            .where((r) => r.path == 'tasks')
            .every((r) => r.queryParameters['limit'] == 1),
        isTrue,
      );
    });

    test('pages 20 at a time by offset', () async {
      final stub = taskStub()
        ..on('GET', 'tasks', (RequestOptions r) {
          final offset = r.queryParameters['offset'] as int;
          return {
            'items': [
              for (var i = offset; i < offset + 20 && i < 45; i++)
                {...rows()[i % 3], 'id': 'task-$i'},
            ],
            'total': 45,
            'offset': offset,
            'limit': 20,
          };
        });
      final container = await tasksContainer(stub);
      listenTo(container, taskListProvider);

      final first = await container.read(taskListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      await container.read(taskListProvider.notifier).loadMore();
      final second = container.read(taskListProvider).requireValue;
      expect(stub.last('GET', 'tasks')?.queryParameters['offset'], 20);
      expect(second.items.map((t) => t.id).toSet(), hasLength(40));
    });

    test('the team filter sends whose tasks to show', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub, role: 'owner');
      listenTo(container, taskListProvider);
      final filter = container.read(taskFilterProvider.notifier);

      filter.apply(const TaskFilter(who: TaskWho.everyone));
      await container.read(taskListProvider.future);
      expect(
        stub.last('GET', 'tasks')?.queryParameters.containsKey('assignee'),
        isFalse,
      );

      filter.apply(const TaskFilter(who: TaskWho.member, memberId: bushraId));
      await container.read(taskListProvider.future);
      expect(stub.last('GET', 'tasks')?.queryParameters['assignee'], bushraId);
    });

    test('offline is a failure with status 0', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      listenTo(container, taskListProvider);
      stub.offline = true;

      await expectLater(
        container.read(taskListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('task changes', () {
    test('ticking off posts done and updates the row in place', () async {
      final stub = taskStub()
        ..on(
          'POST',
          'tasks/{id}/done',
          (RequestOptions r) => {
            ...fixtureMap('tasks_done'),
            'id': r.uri.pathSegments[r.uri.pathSegments.length - 2],
          },
        );
      final container = await tasksContainer(stub);
      listenTo(container, taskListProvider);
      final paged = await container.read(taskListProvider.future);
      final task = paged.items.first;

      final done = await container
          .read(taskListProvider.notifier)
          .complete(task);

      expect(done.isDone, isTrue);
      expect(done.completedOn, isNotNull);
      expect(stub.lastBody('POST', 'tasks/{id}/done'), isEmpty);
      final row = container
          .read(taskListProvider)
          .requireValue
          .items
          .firstWhere((t) => t.id == task.id);
      expect(row.isDone, isTrue);
    });

    test('a refused tick puts the row back and rethrows', () async {
      final stub = taskStub()..fail('POST', 'tasks/{id}/done', 403);
      final container = await tasksContainer(stub);
      listenTo(container, taskListProvider);
      final paged = await container.read(taskListProvider.future);
      final task = paged.items.first;

      await expectLater(
        container.read(taskListProvider.notifier).complete(task),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
      final row = container
          .read(taskListProvider)
          .requireValue
          .items
          .firstWhere((t) => t.id == task.id);
      expect(row.isDone, isFalse);
    });

    test('a new task from a lead posts TaskCreate', () async {
      final stub = taskStub()..on('POST', 'tasks', fixture('tasks_created'));
      final container = await tasksContainer(stub);
      final provider = taskFormProvider(leadId: leadId);
      listenTo(container, provider);

      final draft = await container.read(provider.future);
      expect(draft.lead?.shortName, 'Rahim Traders');

      final form = container.read(provider.notifier)
        ..setTitle('Call Rahim Traders');
      await form.save();

      final body = stub.lastBody('POST', 'tasks');
      expect(body['title'], 'Call Rahim Traders');
      expect(body['type'], 'call');
      expect(body['leadId'], leadId);
      expect(body['remindMin'], 30);
      expect(DateTime.parse(body['dueAt'] as String).isUtc, isTrue);
      expect(body.containsKey('note'), isFalse);
      expect(body.containsKey('assigneeMembershipId'), isFalse);
      expect(
        container.read(provider).requireValue.saved?.id,
        fixtureMap('tasks_created')['id'],
      );
    });

    test('a blank title stops at the form; a 422 lands on its field', () async {
      final stub = taskStub()
        ..fail(
          'POST',
          'tasks',
          422,
          code: 'V-001',
          message: 'Please fill this in',
          field: 'dueAt',
        );
      final container = await tasksContainer(stub);
      final provider = taskFormProvider();
      listenTo(container, provider);
      await container.read(provider.future);
      final form = container.read(provider.notifier);

      await form.save();
      expect(
        container.read(provider).requireValue.failure?.fieldError('title'),
        isNotNull,
      );
      expect(stub.last('POST', 'tasks'), isNull);

      form.setTitle('Visit Delta Power');
      await form.save();
      final failure = container.read(provider).requireValue.failure;
      expect(failure?.isValidation, isTrue);
      expect(failure?.fieldError('dueAt'), 'Please fill this in');
    });

    test('an edit patches TaskUpdate, then reassigns', () async {
      final row = rows().first;
      final id = row['id'] as String;
      final stub = taskStub()
        ..on('PATCH', 'tasks/{id}', {...row, 'title': 'Visit Rahim today'})
        ..on('POST', 'tasks/{id}/assign', {
          ...row,
          'title': 'Visit Rahim today',
          'assigneeMembershipId': bushraId,
          'assigneeName': 'Bushra Nowshin',
        });
      final container = await tasksContainer(stub, role: 'owner');
      final provider = taskFormProvider(taskId: id);
      listenTo(container, provider);

      final draft = await container.read(provider.future);
      expect(draft.title, 'Visit Rahim Traders');
      expect(draft.lead?.id, leadId);
      expect(draft.assignee?.isMe, isTrue);

      final members = await container.read(taskMembersProvider.future);
      container.read(provider.notifier)
        ..setTitle('Visit Rahim today')
        ..setNotes('')
        ..setAssignee(members.firstWhere((m) => m.id == bushraId));
      await container.read(provider.notifier).save();

      final patch = stub.lastBody('PATCH', 'tasks/{id}');
      expect(patch['title'], 'Visit Rahim today');
      expect(patch['type'], 'visit');
      expect(patch['remindMin'], 15);
      expect(patch['note'], '');
      expect(patch.containsKey('leadId'), isFalse);
      expect(stub.lastBody('POST', 'tasks/{id}/assign'), {
        'membershipId': bushraId,
      });
      final saved = container.read(provider).requireValue.saved;
      expect(saved?.assignedTo?.name, 'Bushra Nowshin');
      expect(saved?.assignedToMe, isFalse);
    });

    test('a detail looks through the list; an unknown id is a 404', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      final id = rows()[1]['id'] as String;
      listenTo(container, taskProvider(id));
      listenTo(container, taskProvider('gone'));

      final task = await container.read(taskProvider(id).future);
      expect(task.title, 'Call back Sumaiya about quote');
      final query = stub.last('GET', 'tasks')?.queryParameters;
      expect(query?.containsKey('view'), isFalse);
      expect(query?['limit'], 100);

      await expectLater(
        container.read(taskProvider('gone').future),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });

    test('reschedule moves the due time; delete removes it', () async {
      final row = rows().first;
      final id = row['id'] as String;
      final due = DateTime.utc(2026, 10, 9, 5);
      final stub = taskStub()
        ..on('POST', 'tasks/{id}/move', {
          ...row,
          'dueAt': '2026-10-09T05:00:00Z',
        })
        ..on('DELETE', 'tasks/{id}', null, status: 204);
      final container = await tasksContainer(stub);
      final editor = container.read(taskEditorProvider.notifier);

      final moved = await editor.reschedule(id, due);
      expect(stub.lastBody('POST', 'tasks/{id}/move'), {
        'dueAt': '2026-10-09T05:00:00.000Z',
      });
      expect(moved.dueDate?.toUtc(), due);

      await editor.delete(id);
      expect(stub.last('DELETE', 'tasks/{id}')?.path, 'tasks/$id');
    });
  });

  group('lookups', () {
    test('teammates are the active members, with me marked', () async {
      final container = await tasksContainer(taskStub());
      final members = await container.read(taskMembersProvider.future);

      expect(members.map((m) => m.name.en), [
        'Bushra Nowshin',
        'Rafi Ahmed',
        'Karim Hossain',
        'Nadia Rahman',
      ]);
      expect(members.where((m) => m.isMe).map((m) => m.id), [meId]);
    });

    test('leads search by q, page by offset', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);

      final page = await container
          .read(taskLookupRepositoryProvider)
          .searchLeads(' Rahim ', 2);

      expect(page.items.single.title, '50 cartons soap · November');
      expect(page.items.single.shortName, 'Rahim Traders');
      final query = stub.last('GET', 'leads')?.queryParameters;
      expect(query?['q'], 'Rahim');
      expect(query?['offset'], 20);
    });

    test('a scanned company matches the CRM name loosely', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      final provider = scannedCompanyMatchProvider('RAHIM TRADERS LTD.');
      listenTo(container, provider);

      final id = await container.read(provider.future);

      expect(id, '01a10101-8657-7f15-8630-b08119f1ae61');
      expect(
        stub.last('GET', 'companies')?.queryParameters['q'],
        'RAHIM TRADERS LTD.',
      );
    });
  });

  group('calendar', () {
    test('reads my tasks for the range and merges private events', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      final from = DateTime(2026, 10, 1);
      final to = DateTime(2026, 10, 8);
      final provider = calendarAgendaProvider(from, to);
      listenTo(container, provider);

      final agenda = await container.read(provider.future);

      final query = stub.last('GET', 'tasks')?.queryParameters;
      expect(query?['from'], '2026-10-01');
      expect(query?['to'], '2026-10-07');
      expect(query?['assignee'], meId);
      final items = [
        for (var day = from; day.isBefore(to); day = day.add(oneDay))
          ...agenda.on(day),
      ];
      expect(items.whereType<TaskAgendaItem>(), hasLength(3));
      for (var i = 1; i < items.length; i++) {
        if (!AppDateUtils.isSameDay(items[i].at, items[i - 1].at)) continue;
        expect(items[i].at.isBefore(items[i - 1].at), isFalse);
      }
    });

    test('a saved private event shows on its day', () async {
      final stub = taskStub();
      final container = await tasksContainer(stub);
      final day = DateTime(2026, 11, 3);
      final provider = eventFormProvider(day: day);
      listenTo(container, provider);
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

  group('card scan', () {
    final photo = Uint8List.fromList(List.filled(64, 7));

    test('without a Gemini key scanning is unavailable', () async {
      final container = await tasksContainer(taskStub());
      expect(container.read(cardScanRepositoryProvider), isNull);
      await container.read(scanSessionProvider.future);

      await container
          .read(scanSessionProvider.notifier)
          .scan(photo, ScanMode.card);

      final error = container.read(scanSessionProvider).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).statusCode, scanUnavailable.statusCode);
    });

    test('a scan past the plan limit is a 402 on card scans', () async {
      final billing = fixtureMap('billing');
      final stub = taskStub()
        ..on('GET', 'billing', {
          ...billing,
          'usage': {...billing['usage'] as Map<String, dynamic>, 'scans': 2000},
        });
      final reader = _Reader();
      final container = await tasksContainer(stub, reader: reader);
      await container.read(scanSessionProvider.future);

      await container
          .read(scanSessionProvider.notifier)
          .scan(photo, ScanMode.card);

      final failure = container.read(scanSessionProvider).error;
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).isQuota, isTrue);
      expect(failure.quota, QuotaKind.cardScans);
      expect(reader.scans, 0);
    });

    test('a successful scan is kept for the review, with edits', () async {
      final container = await tasksContainer(taskStub(), reader: _Reader());
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

    test('QR codes: link, vCard, MECARD and plain text', () {
      final link = QrScanResult.parse('https://karimtex.com/catalog/2026');
      expect(
        (link as QrScanResult).link,
        Uri.parse('https://karimtex.com/catalog/2026'),
      );

      final vcard = QrScanResult.parse(
        'BEGIN:VCARD\nVERSION:3.0\nFN:Rezaul Karim\nTITLE:Accounts Manager\n'
        'ORG:Meghna Group\nTEL;TYPE=CELL:+8801715667788\nEND:VCARD',
      );
      final contact = (vcard as CardScanResult).card;
      expect(contact.contactName, 'Rezaul Karim');
      expect(contact.companyName, 'Meghna Group');
      expect(contact.designation, 'Accounts Manager');
      expect(contact.phone, '+8801715667788');

      final me = QrScanResult.parse(
        'MECARD:N:Hossain,Sajib;TEL:+8801812345678;EMAIL:sajib@delta.com;'
        'ORG:Delta Power;;',
      );
      final card = (me as CardScanResult).card;
      expect(card.contactName, 'Sajib Hossain');
      expect(card.companyName, 'Delta Power');
      expect(card.email, 'sajib@delta.com');

      final text = QrScanResult.parse('WIFI:T:WPA;S:Office;P:x;;');
      expect((text as QrScanResult).link, isNull);
    });
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

    final taskId = rows().first['id'] as String;
    final screens = <String, (Widget, String?)>{
      'tasks': (const TasksScreen(), 'Call back Sumaiya about quote'),
      'task detail': (TaskDetailScreen(id: taskId), 'Mark done'),
      'new task': (
        const TaskFormScreen(leadId: leadId),
        'Rahim Traders (lead)',
      ),
      'edit task': (TaskFormScreen(taskId: taskId), 'Edit task'),
      'calendar': (const CalendarScreen(), null),
      'private event': (const PrivateEventScreen(), 'Private event'),
      'scan capture': (
        const ScanCaptureScreen(),
        'Card scanning isn\'t available',
      ),
      'scan review': (const ScanReviewScreen(), 'No card scanned'),
      'scan lead': (const ScanLeadScreen(), 'No card scanned'),
      'qr result': (const QrResultScreen(), 'No QR code scanned'),
    };

    for (final locale in [english, bangla]) {
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets('$name in ${locale.languageCode}', (tester) async {
          final container = await tester.runAsync(
            () => tasksContainer(taskStub(), role: 'owner', fullAccess: true),
          );
          if (container == null) return;

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

const oneDay = Duration(days: 1);

List<Map<String, dynamic>> rows() =>
    (fixtureMap('tasks_list')['items'] as List).cast<Map<String, dynamic>>();

/// The task screens' endpoints, answering from the recorded fixtures.
ApiStub taskStub() => ApiStub()
  ..on('GET', 'tasks', fixture('tasks_list'))
  ..on('GET', 'workspaces/members', fixture('tasks_members'))
  ..on('GET', 'leads/{id}', fixture('tasks_lead'))
  ..on('GET', 'leads', fixture('tasks_leads'))
  ..on('GET', 'companies', fixture('tasks_companies'));

/// A signed-in container over [stub] as Rafi with [role], with the
/// workspace loaded and fake latency off for the private events.
Future<ProviderContainer> tasksContainer(
  ApiStub stub, {
  String role = 'executive',
  bool fullAccess = false,
  CardScanRepository? reader,
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: 'standard'),
    overrides: [
      if (reader != null) cardScanRepositoryProvider.overrideWithValue(reader),
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
      .update((s) => s.copyWith(latency: false));
  await container.read(workspacesProvider.future);
  return container;
}

void listenTo(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}

class _Reader implements CardScanRepository {
  int scans = 0;

  @override
  Future<ScanResult> scan(
    Uint8List image, {
    ScanMode mode = ScanMode.card,
  }) async {
    scans++;
    return const CardScanResult(
      ScannedCard(
        contactName: 'Md. Karim',
        companyName: 'Karim Textiles Ltd.',
        phones: ['+880 1711-234567'],
      ),
    );
  }
}
