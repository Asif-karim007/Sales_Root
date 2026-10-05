import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

const rafiId = '01a10101-8656-7886-b8e5-4f197fbd9159';
const rumpaId = '01a10101-8654-7500-9b5b-0704cbb7d210';
const casualId = '01a10131-38c6-76c6-a2f5-a2b8a0687914';
const sickId = '01a10131-38cd-75b9-afa8-2361848111c5';
const travelId = '01a10131-4df2-7c8f-9306-2f72b762c1f0';
const mobileId = '01a10131-4df8-7db6-85c3-a19a251a77fe';
const visitId = '01a10d05-f45b-710c-9095-806e0018311f';
const ticketId = '01a10d28-49e3-70fb-903b-0e5967db8cce';
const companyId = '01a10ced-83f6-79b3-a0c8-6af41cdf05fe';

/// Every HR endpoint, answering from the recorded responses of the test
/// user. Writes answer as the server did: an id, or no content.
ApiStub hrStub() => ApiStub()
  ..on('GET', 'hr/leave/types', fixture('hr_leave_types'))
  ..on('GET', 'hr/leave/balance', fixture('hr_leave_balance'))
  ..on('GET', 'hr/leave', fixture('hr_leave_list'))
  ..on('POST', 'hr/leave', fixture('hr_leave_created'))
  ..on('POST', 'hr/leave/{id}/cancel', null, status: 204)
  ..on('GET', 'hr/holidays', fixture('hr_leave_holidays'))
  ..on('GET', 'hr/expenses/categories', fixture('hr_expense_categories'))
  ..on('GET', 'hr/expenses', fixture('hr_expenses'))
  ..on('POST', 'hr/expenses', fixture('hr_expense_created'))
  ..on('DELETE', 'hr/expenses/{id}', null, status: 204)
  ..on(
    'GET',
    'approvals',
    (r) => r.queryParameters['status'] == 'pending'
        ? fixture('hr_approvals')
        : <Object>[],
  )
  ..on('POST', 'approvals/{id}/{action}', null, status: 204)
  ..on('GET', 'hr/payslips/me', fixture('hr_payslips_me'))
  ..on('GET', 'hr/salary/me', null)
  ..on('GET', 'workspaces/members', fixture('hr_members'))
  ..on('GET', 'visits', fixture('hr_visits'))
  ..on('GET', 'companies', fixture('hr_companies'))
  ..on('POST', 'tickets', fixture('hr_ticket_created'))
  ..on('GET', 'tickets/{id}', fixture('hr_ticket'))
  ..on('PATCH', 'tickets/{id}', null, status: 204)
  ..on('POST', 'tickets/{id}/reply', null, status: 204)
  ..on('POST', 'files', fixture('hr_uploaded'));

/// A signed-in container over [stub] as Rafi with [role], whose workspace and
/// grants are loaded. [fullAccess] grants every right in every module.
Future<ProviderContainer> hrContainer(
  ApiStub stub, {
  String role = 'executive',
  bool fullAccess = false,
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: 'standard'),
    overrides: <Override>[
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
  container.listen(currentWorkspaceProvider, (_, _) {});
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}

/// Keeps an auto-dispose provider alive for the test.
void listenTo(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}

/// A small photo on disk, as the camera would leave one.
String photoFile() {
  final dir = Directory.systemTemp.createTempSync('hr_photo');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/receipt.jpg')..writeAsBytesSync([1, 2, 3]);
  return file.path;
}
