import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/growth/data/inbox_fixtures.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';

import 'growth_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unanswered leads come first, longest waiting on top', () async {
    final container = await growthContainer();
    final paged = await container.read(inboxListProvider.future);

    final statuses = [for (final lead in paged.items) lead.status];
    final firstAssigned = statuses.indexOf(InboxStatus.assigned);
    expect(firstAssigned, greaterThan(0));
    expect(statuses.skip(firstAssigned), everyElement(InboxStatus.assigned));
    final fresh = paged.items.take(firstAssigned).toList();
    for (var i = 1; i < fresh.length; i++) {
      expect(
        fresh[i - 1].waitingAtFetch,
        greaterThanOrEqualTo(fresh[i].waitingAtFetch),
      );
    }
    expect(fresh.first.name, 'Rokon Uddin');
    expect(
      paged.items.map((l) => l.status),
      isNot(contains(InboxStatus.accepted)),
    );
  });

  test('the late filter keeps only leads past the SLA', () async {
    final container = await growthContainer();
    container.read(inboxFilterProvider.notifier).set(InboxFilter.late);
    final paged = await container.read(inboxListProvider.future);

    expect(paged.items, isNotEmpty);
    for (final lead in paged.items) {
      expect(lead.status, InboxStatus.fresh);
      expect(lead.waitingAtFetch.inMinutes, greaterThanOrEqualTo(15));
    }
    expect(paged.facets['Counts']?['Late'], paged.items.length);
  });

  test('pages load 20 at a time', () async {
    final container = await growthContainer();
    final table = backendOf(container).table(growthInboxTable, inboxFixtures);
    for (var i = 0; i < 10; i++) {
      table.insert({
        'Name': 'Extra lead $i',
        'Phone': '+88017000000$i',
        'Source': 'Website',
        'Status': 'New',
        'ReceivedAt': jsonUtc(DateTime.now()),
      });
    }

    final first = await container.read(inboxListProvider.future);
    expect(first.items, hasLength(20));
    expect(first.hasMore, isTrue);

    await container.read(inboxListProvider.notifier).loadMore();
    final next = container.read(inboxListProvider).requireValue;
    expect(next.items.length, first.totalCount);
    expect(next.hasMore, isFalse);
  });

  test(
    'accepting assigns by rule and takes the lead out of the inbox',
    () async {
      final container = await growthContainer();
      await container.read(inboxListProvider.future);
      final notifier = container.read(acceptLeadSubmitProvider(1).notifier);
      final sub = container.listen(acceptLeadSubmitProvider(1), (_, _) {});
      addTearDown(sub.close);

      await notifier.submit(const AcceptInput(stageId: 1));

      final accepted = container.read(acceptLeadSubmitProvider(1)).requireValue;
      expect(accepted?.status, InboxStatus.accepted);
      expect(accepted?.assignedToId, 5);
      expect(accepted?.assignedByRule, 'Uttara & Mirpur → Dhaka North');
      final paged = await container.read(inboxListProvider.future);
      expect(paged.items.map((l) => l.id), isNot(contains(1)));

      await expectLater(
        container
            .read(leadInboxRepositoryProvider)
            .accept(1, const AcceptInput(stageId: 1)),
        throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 409)),
      );
    },
  );

  test('rejecting and assigning update the inbox', () async {
    final container = await growthContainer();
    final actions = container.read(inboxActionsProvider.notifier);

    final rejected = await actions.reject(2, RejectReason.spam);
    expect(rejected.status, InboxStatus.rejected);

    final assigned = await actions.assign(3, 1);
    expect(assigned.status, InboxStatus.assigned);
    expect(assigned.assignedTo?.en, 'Karim Hossain');

    container.read(inboxFilterProvider.notifier).set(InboxFilter.mine);
    final mine = await container.read(inboxListProvider.future);
    expect(mine.items.map((l) => l.id), contains(3));
    expect(mine.items.map((l) => l.id), isNot(contains(2)));
  });

  test('a duplicate number is flagged', () async {
    final container = await growthContainer();
    final lead = await container.read(inboxLeadProvider(4).future);
    expect(lead.duplicate, isNotNull);
    expect(lead.duplicate?.companyName, lead.name);
  });

  test('a member cannot accept, and offline fails with status 0', () async {
    final member = await growthContainer(role: WorkspaceRole.member);
    await expectLater(
      member
          .read(leadInboxRepositoryProvider)
          .accept(1, const AcceptInput(stageId: 1)),
      throwsA(
        isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', true),
      ),
    );

    final offline = await growthContainer();
    goOffline(offline);
    await expectLater(
      offline.read(inboxListProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });
}
