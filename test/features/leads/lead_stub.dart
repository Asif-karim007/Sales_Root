import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

const rahimId = '01a10101-866a-7007-90bc-2326bcdb9d50';
const meMemberId = '01a10101-8656-7886-b8e5-4f197fbd9159';
const toContactStage = '01a10101-864b-7935-9bd6-8c6f4179ed51';
const visitedStage = '01a10101-864c-74b1-85f5-ec67557a0a62';
const sampleStage = '01a10101-864c-753e-85da-61aec3aed636';
const orderedStage = '01a10101-864d-7b1d-a937-209e6db5ff2d';
const lostStage = '01a10101-864d-7c3b-a5cc-60e0522176b8';

/// One page of `GET leads` built from the recorded rows, as the server would
/// page [total] leads: row `i` gets the id `lead-i`.
Map<String, dynamic> leadPage(RequestOptions request, {int total = 3}) {
  final rows = fixtureMap('leads_list')['items'] as List;
  final offset = int.parse('${request.queryParameters['offset'] ?? 0}');
  final limit = int.parse('${request.queryParameters['limit'] ?? 20}');
  final end = (offset + limit).clamp(0, total);
  return {
    'items': [
      for (var i = offset; i < end; i++)
        {
          ...rows[i % rows.length] as Map<String, dynamic>,
          if (total > rows.length) 'id': 'lead-$i',
        },
    ],
    'total': total,
    'offset': offset,
    'limit': limit,
  };
}

/// The lead endpoints answered from recorded responses.
ApiStub leadStub({int total = 3}) => ApiStub()
  ..on('GET', 'leads', (RequestOptions r) => leadPage(r, total: total))
  ..on('GET', 'leads/{id}', fixture('leads_detail'))
  ..on('GET', 'leads/check-phone', fixture('leads_check_phone'))
  ..on('GET', 'workspaces/pipelines', fixture('leads_pipelines'))
  ..on('GET', 'workspaces/current', fixture('leads_workspace'))
  ..on('GET', 'workspaces/members', fixture('leads_members'))
  ..on('GET', 'companies', fixture('leads_companies'))
  ..on('GET', 'companies/{id}', fixture('leads_company'))
  ..on('GET', 'contacts', fixture('leads_contacts'))
  ..on('GET', 'contacts/{id}', fixture('leads_contact'))
  ..on('GET', 'ai/status', fixture('leads_ai_status'));

/// A signed-in container on [stub] with the workspace, grants and plan
/// loaded, so the repository is scoped and the screens know what to offer.
Future<ProviderContainer> leadContainer(
  ApiStub stub, {
  String role = 'executive',
  String level = 'standard',
  List<Override> overrides = const [],
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: level),
    overrides: overrides,
  );
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  await container.read(planProvider.future);
  return container;
}
