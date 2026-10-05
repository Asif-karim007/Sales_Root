import 'package:salesroot/core/fake/seed_graph.dart';

const growthMembersTable = 'growth_members';
const growthRulesTable = 'growth_rules';
const growthDistributionTable = 'growth_distribution';

/// Lead form and campaign names the rules can match.
const distributionFormNames = [
  'Dealer application',
  'SolarOct26',
  'Website enquiry',
  'Eid offer 2026',
];

/// Members as distribution sees them today: leave, check-in and load.
List<Map<String, dynamic>> growthMemberFixtures(SeedGraph graph) {
  final random = graph.random('growth_members');
  return [
    for (final member in graph.members)
      {
        'Id': member.id,
        'id': '${member.id}',
        'name': member.name,
        'nameBn': member.nameBn,
        'onLeave': member.id != SeedGraph.meId && member.id % 6 == 0,
        'checkedIn': member.id == SeedGraph.meId || member.id % 4 != 0,
        'openLeads': graph.leadsOf(member.id).where((l) => l.isOpen).length,
        'assignedToday': random.nextInt(4),
      },
  ];
}

List<Map<String, dynamic>> distributionSettingsFixtures(SeedGraph graph) => [
  {'Id': 1, 'Enabled': true},
];

List<Map<String, dynamic>> distributionRuleFixtures(SeedGraph graph) {
  final members = graph.members;
  int at(int index) => members[index % members.length].id;
  String first(int id) => graph.member(id).name.split(' ').first;
  final dealerOwner = at(2);
  final north = {for (var i = 3; i < 10; i++) at(i)}.toList();
  final solar = {at(3), at(4)}.toList();
  final website = {at(5), at(6), at(8)}.toList();
  return [
    {
      'Id': 1,
      'Position': 1,
      'Name': 'Dealer applications → ${first(dealerOwner)}',
      'Enabled': true,
      'Forms': ['Dealer application'],
      'Mode': 'Member',
      'MemberIds': [dealerOwner],
      'SkipOnLeave': false,
      'EscalateMinutes': 30,
    },
    {
      'Id': 2,
      'Position': 2,
      'Name': 'Uttara & Mirpur → Dhaka North',
      'Enabled': true,
      'Areas': ['Uttara', 'Mirpur', 'Tongi'],
      'Mode': 'RoundRobin',
      'MemberIds': north,
      'OnlyCheckedIn': true,
      'SkipOnLeave': true,
      'FallbackMemberId': dealerOwner,
      'EscalateMinutes': 15,
      'Cursor': 0,
    },
    {
      'Id': 3,
      'Position': 3,
      'Name': 'Solar ads → ${solar.map(first).join(', ')}',
      'Enabled': true,
      'Sources': ['Facebook'],
      'Forms': ['SolarOct26'],
      'Mode': 'RoundRobin',
      'MemberIds': solar,
      'SkipOnLeave': true,
      'EscalateMinutes': 15,
      'Cursor': 1,
    },
    {
      'Id': 4,
      'Position': 4,
      'Name': 'Website enquiries → lightest load',
      'Enabled': true,
      'Sources': ['Website'],
      'Mode': 'ByLoad',
      'MemberIds': website,
      'SkipOnLeave': true,
      'Days': [6, 7, 1, 2, 3, 4],
      'FromHour': 9,
      'ToHour': 18,
      'DailyCap': 8,
    },
    {
      'Id': 5,
      'Position': 5,
      'Name': 'Weekend WhatsApp → ${first(at(1))}',
      'Enabled': false,
      'Sources': ['WhatsApp'],
      'Mode': 'Member',
      'MemberIds': [at(1)],
      'Days': [5],
    },
    {
      'Id': 6,
      'Position': 6,
      'Name': 'Everything else → shared queue',
      'Enabled': true,
      'Mode': 'Queue',
      'EscalateMinutes': 15,
    },
  ];
}
