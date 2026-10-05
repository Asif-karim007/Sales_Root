import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

const ticketId = '01a10d28-49e3-70fb-903b-0e5967db8cce';

/// The support endpoints, answering from the recorded responses of the test
/// user. Writes answer as the server did: an id, or no content.
ApiStub supportStub() => ApiStub()
  ..on('GET', 'help/tickets', fixture('support_help_tickets'))
  ..on('GET', 'help/tickets/{id}', fixture('support_ticket'))
  ..on('POST', 'help/ticket', {'id': ticketId})
  ..on('POST', 'help/tickets/{id}/reply', null, status: 204)
  ..on('POST', 'help/feedback', null, status: 204)
  ..on('GET', 'ai/status', fixture('support_ai_status'))
  ..on('POST', 'ai/guide', fixture('support_guide_answer'))
  ..on('POST', 'ai/guide/rate', null, status: 204)
  ..on('POST', 'files', fixture('support_uploaded'));

/// A signed-in executive over [stub]; the academy and help articles stay on
/// the fake backend, with its latency off.
Future<ProviderContainer> supportApiContainer(ApiStub stub) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: 'executive', level: 'standard'),
  );
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false));
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

/// A small file on disk, as the gallery would hand one over.
String pickedFile(String name) {
  final dir = Directory.systemTemp.createTempSync('support_file');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3]);
  return file.path;
}
