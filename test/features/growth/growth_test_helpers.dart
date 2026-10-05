import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

const rafi = '01a10101-8656-7886-b8e5-4f197fbd9159';
const bushra = '01a10101-8656-7ec4-8e2a-2f921b517ab4';
const leadId = '01a10101-866a-7007-90bc-2326bcdb9d50';
const companyId = '01a10101-8657-7f15-8630-b08119f1ae61';
const metaId = '01a20000-0000-7000-a000-000000000001';
const whatsappId = '01a20000-0000-7000-a000-000000000002';
const formId = '01a20000-0000-7000-a000-000000000003';
const sentCampaign = '01a20000-0000-7000-a000-000000000010';
const scheduledCampaign = '01a20000-0000-7000-a000-000000000011';

String conversationId(int n) =>
    '01a30000-0000-7000-a000-${n.toString().padLeft(12, '0')}';

// The test user's inbox, campaigns, forms, templates and integrations are
// all empty on the server, so the rows below follow the request schemas
// and the lead's own keys; they are the app's guess, not recordings.

Map<String, dynamic> conversationRow(
  int n, {
  String? assignedTo,
  bool closed = false,
  bool withLead = false,
}) => {
  'id': conversationId(n),
  'channel': n.isEven ? 'whatsapp' : 'messenger',
  'contactName': 'Customer $n',
  'phone': '+88017110000${n.toString().padLeft(2, '0')}',
  'status': closed ? 'closed' : 'open',
  'assignedMembershipId': assignedTo,
  'assigneeName': assignedTo == null
      ? null
      : assignedTo == rafi
      ? 'Rafi Ahmed'
      : 'Bushra Nowshin',
  'leadId': withLead ? leadId : null,
  'lastMessageText': 'Price of 50 cartons?',
  'lastDirection': 'in',
  'lastMessageAt': '2026-10-05T0${n % 10}:15:00Z',
  'unreadCount': n % 3,
  'createdAt': '2026-10-05T03:00:00Z',
};

/// `GET inbox/{id}`, wrapped as `{conversation, messages}`.
Map<String, dynamic> conversationDetail(Map<String, dynamic> row) => {
  'conversation': row,
  'messages': [
    {
      'id': 'm1',
      'direction': 'in',
      'text': 'Price of 50 cartons?',
      'createdAt': '2026-10-05T03:00:00Z',
    },
    {
      'id': 'm2',
      'direction': 'out',
      'text': 'Sending the list now.',
      'status': 'read',
      'createdAt': '2026-10-05T03:05:00Z',
    },
  ],
};

/// An inbox whose rows answer by `offset`/`limit`, and whose detail is the
/// row with its messages.
void stubInbox(ApiStub stub, List<Map<String, dynamic>> rows) => stub
  ..on('GET', 'inbox', (RequestOptions r) {
    final offset = r.queryParameters['offset'] as int? ?? 0;
    final limit = r.queryParameters['limit'] as int? ?? 50;
    return {
      'items': rows.skip(offset).take(limit).toList(),
      'total': rows.length,
      'offset': offset,
      'limit': limit,
    };
  })
  ..on('GET', 'inbox/{id}', (RequestOptions r) {
    final id = r.uri.pathSegments.last;
    final row = rows.where((row) => row['id'] == id).firstOrNull;
    return row == null
        ? StubReply(404, fixture('growth_not_found'))
        : conversationDetail(row);
  });

final integrationRows = [
  {
    'id': metaId,
    'provider': 'meta',
    'displayName': 'Rahim Traders',
    'status': 'active',
    'createdAt': '2026-09-20T05:00:00Z',
  },
  {
    'id': whatsappId,
    'provider': 'whatsapp',
    'displayName': '+8801711000099',
    'status': 'active',
    'createdAt': '2026-09-21T05:00:00Z',
  },
];

final formRows = [
  {
    'id': formId,
    'name': 'Website enquiry',
    'slug': 'dhaka-sales-enquiry',
    'language': 'bn',
    'isActive': true,
  },
];

final templateRows = [
  {
    'id': 't1',
    'channel': 'whatsapp',
    'name': 'price_list',
    'language': 'bn',
    'body': 'Hello {{name}}, here is our price list.',
    'status': 'approved',
  },
  {
    'id': 't2',
    'channel': 'whatsapp',
    'name': 'thanks',
    'language': 'en',
    'body': 'Thanks {{name}}!',
    'status': 'pending',
  },
];

final campaignRows = [
  {
    'id': scheduledCampaign,
    'name': 'Eid offer',
    'channel': 'sms',
    'status': 'scheduled',
    'audience': '{"status": "open"}',
    'body': 'Eid Mubarak {{name}}! 10% off this week.',
    'recipientCount': 6,
    'scheduledAt': '2026-10-08T04:00:00Z',
  },
  {
    'id': sentCampaign,
    'name': 'November price list',
    'channel': 'sms',
    'status': 'sent',
    'audience': {'status': 'won'},
    'body': 'New prices from 1 November.',
    'recipientCount': 40,
    'sentCount': 40,
    'deliveredCount': 36,
    'failedCount': 4,
    'replyCount': 3,
    'sentAt': '2026-10-01T04:00:00Z',
  },
];

/// The growth API for Rafi's workspace; [empty] answers every list with the
/// recorded (empty) responses.
ApiStub growthStub({bool empty = false}) {
  final stub = ApiStub()
    ..on('GET', 'workspaces/members', fixture('growth_members'))
    ..on('POST', 'ai/draft', fixture('growth_ai_draft'))
    ..on('POST', 'campaigns/preview', (RequestOptions r) {
      final body = r.data is String ? jsonDecode(r.data as String) : r.data;
      final audience = (body as Map)['audience'] as Map;
      return fixture(
        audience['source'] == 'facebook'
            ? 'growth_campaign_preview_facebook'
            : 'growth_campaign_preview',
      );
    })
    ..on('GET', 'campaigns/{id}', (RequestOptions r) {
      final id = r.uri.pathSegments.last;
      final row = campaignRows.where((row) => row['id'] == id).firstOrNull;
      return row ?? StubReply(404, fixture('growth_not_found'));
    });
  if (empty) {
    stubInbox(stub, const []);
    return stub
      ..on('GET', 'integrations', fixture('growth_integrations'))
      ..on('GET', 'forms', fixture('growth_forms'))
      ..on('GET', 'inbox', fixture('growth_inbox'))
      ..on('GET', 'templates', fixture('growth_templates'))
      ..on('GET', 'campaigns', fixture('growth_campaigns'));
  }
  stubInbox(stub, [
    conversationRow(1),
    conversationRow(2, assignedTo: rafi, withLead: true),
    conversationRow(3, assignedTo: bushra),
    conversationRow(4, closed: true),
  ]);
  return stub
    ..on('GET', 'integrations', integrationRows)
    ..on('GET', 'forms', formRows)
    ..on('GET', 'templates', templateRows)
    ..on('GET', 'campaigns', campaignRows);
}

/// A signed-in container over [stub] in Rafi's workspace as [role], with
/// the workspace loaded and fake latency off for notices and rules.
Future<ProviderContainer> growthContainer({
  ApiStub? stub,
  String role = 'owner',
}) async {
  final container = await apiContainer(
    stub ?? growthStub(),
    me: meWith(role: role),
  );
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false));
  await container.read(workspacesProvider.future);
  return container;
}
