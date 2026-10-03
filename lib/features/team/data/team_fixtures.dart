import 'package:collection/collection.dart';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

const _areas = [
  ('Dhaka North', 'ঢাকা উত্তর'),
  ('Dhaka South', 'ঢাকা দক্ষিণ'),
  ('Chattogram', 'চট্টগ্রাম'),
];

/// The mail domain of the workspace's members.
String teamDomain(SeedGraph graph) => switch (graph.workspaceId) {
  200 => 'dhakasales.com',
  300 => 'nexzenpartners.com',
  _ => 'gmail.com',
};

/// The id of the workspace owner, the fallback manager.
int ownerIdOf(SeedGraph graph) =>
    graph.members.firstWhereOrNull((m) => m.role == WorkspaceRole.owner)?.id ??
    SeedGraph.meId;

/// The member's manager, or the owner when the seeded one isn't in this
/// workspace.
int? managerIdOf(SeedGraph graph, SeedMember member) {
  final managerId = member.managerId;
  if (managerId == null || member.role == WorkspaceRole.owner) return null;
  final exists = graph.members.any((m) => m.id == managerId);
  return exists ? managerId : ownerIdOf(graph);
}

List<Map<String, dynamic>> memberFixtures(SeedGraph graph) {
  final random = graph.random('team-members');
  final leads = graph.members
      .where((m) => m.role == WorkspaceRole.teamLead)
      .toList();
  (String, String)? areaOf(SeedMember member) {
    final leadId = member.role == WorkspaceRole.teamLead
        ? member.id
        : managerIdOf(graph, member);
    final index = leads.indexWhere((l) => l.id == leadId);
    return index < 0 ? null : _areas[index % _areas.length];
  }

  final lastId = graph.members.length > 12 ? graph.members.last.id : null;
  return [
    for (final member in graph.members)
      _member(graph, member, random.nextInt(100), areaOf(member), lastId),
  ];
}

Map<String, dynamic> _member(
  SeedGraph graph,
  SeedMember member,
  int roll,
  (String, String)? area,
  int? deactivatedId,
) {
  final pinned =
      member.id == SeedGraph.meId || member.role != WorkspaceRole.member;
  final deactivated = member.id == deactivatedId;
  final (status, offlineDays) = switch (roll) {
    _ when deactivated => ('Deactivated', 0),
    _ when member.id == 6 => ('Offline', 2),
    _ when pinned => ('Active', 0),
    < 70 => ('Active', 0),
    < 80 => ('NotStarted', 0),
    < 88 => ('OnLeave', 0),
    _ => ('Offline', 2 + roll % 4),
  };
  final first = member.name.split(' ').first.toLowerCase();
  return {
    'Id': member.id,
    'Name': member.name,
    'NameBn': member.nameBn,
    'Code': 'EMP-${member.id.toString().padLeft(3, '0')}',
    'Designation': member.designation,
    'PhoneNumbers': [member.phone],
    'Emails': ['$first@${teamDomain(graph)}'],
    'Role': member.role.wire,
    'Level': switch (member.role) {
      WorkspaceRole.owner => 'Advanced',
      WorkspaceRole.teamLead => 'Standard',
      WorkspaceRole.member => roll.isEven ? 'Easy' : 'Standard',
    },
    'ManagerId': managerIdOf(graph, member),
    'Area': area?.$1,
    'AreaBn': area?.$2,
    'StatusToday': status,
    'OfflineDays': offlineDays,
    'IsActive': !deactivated,
    'JoiningDate': jsonUtc(
      graph.daysAgo(member.role == WorkspaceRole.owner ? 900 : 40 + roll * 7),
    ),
    'DutyStart': '09:00',
    'DutyEnd': '18:00',
    'TrackingConsent': roll % 5 != 0,
  }..removeWhere((_, value) => value == null);
}

List<Map<String, dynamic>> inviteFixtures(SeedGraph graph) {
  if (graph.members.length < 2) return [];
  final owner = ownerIdOf(graph);
  final firstLead = graph.members
      .firstWhereOrNull((m) => m.role == WorkspaceRole.teamLead)
      ?.id;
  return [
    _invite(
      graph,
      id: 1,
      code: 'TH7K2QPM',
      name: 'Tanvir Hasan',
      phone: '+8801912345678',
      managerId: firstLead ?? owner,
      level: 'Easy',
      daysAgo: 2,
    ),
    _invite(
      graph,
      id: 2,
      code: 'SA4R9WXC',
      name: 'Sadia Afrin',
      phone: '+8801713456789',
      managerId: owner,
      level: 'Standard',
      daysAgo: 5,
    ),
  ];
}

Map<String, dynamic> _invite(
  SeedGraph graph, {
  required int id,
  required String code,
  required String name,
  required String phone,
  required int managerId,
  required String level,
  required int daysAgo,
}) => {
  'Id': id,
  'Code': code,
  'Link': inviteLink(code),
  'Name': name,
  'Phone': phone,
  'Role': WorkspaceRole.member.wire,
  'ManagerId': managerId,
  'Level': level,
  'FieldForce': true,
  'TeamOnlyCapture': false,
  'SentAt': jsonUtc(graph.daysAgo(daysAgo, hour: 11, minute: 20)),
};

String inviteLink(String code) =>
    'https://salesrootcrm.com${Routes.acceptInviteFor(code)}';

const List<(int, int)> seatPackPrices = [(1, 299), (5, 1399), (10, 2599)];
