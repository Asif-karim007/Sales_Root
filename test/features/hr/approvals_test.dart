import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/hr/models/approval.dart';
import 'package:salesroot/features/hr/providers/approvals_providers.dart';

import '../../helpers/api_stub.dart';
import 'hr_test_setup.dart';

void main() {
  test('an executive cannot approve', () async {
    final container = await hrContainer(hrStub());
    expect(
      container.read(moduleAccessProvider(AppModule.approvals)).canApprove,
      isFalse,
    );
  });

  test('the inbox reads the real JSON with counts by kind', () async {
    final stub = hrStub();
    final container = await hrContainer(stub, role: 'owner');
    listenTo(container, approvalListProvider);

    final paged = await container.read(approvalListProvider.future);

    expect(stub.last('GET', 'approvals')?.queryParameters, {
      'box': 'inbox',
      'status': 'pending',
    });
    expect(paged.items, hasLength(3));
    final expense = paged.items.first;
    expect(expense.kind, ApprovalKind.expense);
    expect(expense.employeeName, 'Rafi Ahmed');
    expect(expense.summary, 'Travel / transport ৳100 · 01 Jun');
    expect(expense.reason, '[test] old');
    expect(expense.amount, 100);
    expect(expense.isPending, isTrue);
    expect(paged.facets[approvalCountsFacet], {
      'pending': 3,
      'leave': 1,
      'expense': 2,
      'collection': 0,
    });
  });

  test('a kind chip narrows the list; done asks for decided ones', () async {
    final stub = hrStub();
    final container = await hrContainer(stub, role: 'owner');
    listenTo(container, approvalListProvider);

    container.read(approvalFilterProvider.notifier).set(ApprovalFilter.leave);
    final leave = await container.read(approvalListProvider.future);
    expect(leave.items.single.kind, ApprovalKind.leave);
    expect(leave.items.single.summary, startsWith('Casual leave'));

    container.read(approvalFilterProvider.notifier).set(ApprovalFilter.done);
    final done = await container.read(approvalListProvider.future);
    expect(done.items, isEmpty);
    final statuses = {
      for (final r in stub.requests)
        if (r.path == 'approvals') r.queryParameters['status'],
    };
    expect(statuses, containsAll(['pending', 'approved', 'rejected']));
  });

  test('approve and reject post the decision with the note', () async {
    final stub = hrStub();
    final container = await hrContainer(stub, role: 'owner');
    listenTo(container, approvalActionsProvider);
    final actions = container.read(approvalActionsProvider.notifier);

    await actions.decide(const ApprovalDecision(id: 'a1', approve: true));
    expect(
      stub.last('POST', 'approvals/{id}/{action}')?.path,
      'approvals/a1/approve',
    );
    expect(stub.lastBody('POST', 'approvals/{id}/{action}'), isEmpty);

    await actions.decide(
      const ApprovalDecision(id: 'a2', approve: false, reason: ' No bill '),
    );
    expect(
      stub.last('POST', 'approvals/{id}/{action}')?.path,
      'approvals/a2/reject',
    );
    expect(stub.lastBody('POST', 'approvals/{id}/{action}'), {
      'note': 'No bill',
    });
    expect(container.read(approvalActionsProvider).value?.approved, isFalse);
  });

  test('approve all decides every pending request', () async {
    final stub = hrStub();
    final container = await hrContainer(stub, role: 'owner');
    listenTo(container, approvalActionsProvider);
    final items = (await container.read(approvalListProvider.future)).items;

    await container.read(approvalActionsProvider.notifier).approveAll(items);

    expect(container.read(approvalActionsProvider).value?.count, 3);
    final decided = stub.requests.where(
      (r) => r.method == 'POST' && r.path.startsWith('approvals/'),
    );
    expect(decided, hasLength(3));
  });

  test('a decision without the right is a 403', () async {
    final stub = hrStub()
      ..on(
        'POST',
        'approvals/{id}/{action}',
        fixture('hr_approval_forbidden'),
        status: 403,
      );
    final container = await hrContainer(stub);
    listenTo(container, approvalActionsProvider);

    await container
        .read(approvalActionsProvider.notifier)
        .decide(const ApprovalDecision(id: 'a1', approve: true));

    expect(
      container.read(approvalActionsProvider).error,
      isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', isTrue),
    );
  });
}
