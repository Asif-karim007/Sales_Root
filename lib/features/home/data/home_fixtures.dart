import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

const _notes = [
  'discuss quotation',
  'কোটেশন নিয়ে কথা',
  'site survey for rooftop',
  'ইনভার্টার ডেমো দেখাতে হবে',
  'price negotiation',
  'payment follow-up',
  '5kW kit er details pathate hobe',
  'battery warranty question',
  'নেট মিটারিং কাগজ',
  'confirm installation date',
];

const _ownTasks = [
  ('Submit weekly visit report', 'Task'),
  ('Collect cheque from accounts', 'Task'),
  ('Team meeting — monthly target', 'Meeting'),
  ('Update panel price list', 'Task'),
  ('Warehouse stock check — 550W panels', 'Task'),
];

/// The signed-in user's tasks: one per open lead, plus a few of their own.
/// Due dates spread from a few days overdue to next week.
List<Map<String, dynamic>> homeTaskFixtures(SeedGraph graph) {
  final random = graph.random('home-tasks');
  final leads = graph.leadsOf(SeedGraph.meId).where((l) => l.isOpen).toList();
  const offsets = [-4, -2, -1, 0, 0, 0, 0, 1, 2, 3, 6];
  final rows = <Map<String, dynamic>>[];
  for (final lead in leads) {
    final offset = offsets[random.nextInt(offsets.length)];
    final kind = _kindFor(lead, random.nextInt(3));
    final done = offset < 0 && random.nextInt(3) == 0;
    rows.add({
      'Id': rows.length + 1,
      'Title': lead.title,
      'Kind': kind,
      'LeadId': lead.id,
      'AssigneeId': SeedGraph.meId,
      'DueAt': jsonUtc(
        graph.daysAhead(
          offset,
          hour: 9 + random.nextInt(9),
          minute: random.nextBool() ? 0 : 30,
        ),
      ),
      'IsDone': done,
      'Note': _notes[random.nextInt(_notes.length)],
    });
  }
  for (final (title, kind) in _ownTasks) {
    final offset = random.nextInt(3);
    rows.add({
      'Id': rows.length + 1,
      'Title': title,
      'Kind': kind,
      'AssigneeId': SeedGraph.meId,
      'DueAt': jsonUtc(graph.daysAhead(offset, hour: 15 + random.nextInt(3))),
      'IsDone': false,
    });
  }
  return rows;
}

String _kindFor(SeedLead lead, int roll) => switch (lead.stageId) {
  1 => roll == 0 ? 'WhatsApp' : 'Call',
  2 => 'FollowUp',
  3 => roll == 0 ? 'Visit' : 'Call',
  _ => roll == 0 ? 'Meeting' : 'FollowUp',
};

/// Leave and expense requests waiting for the team lead or owner.
List<Map<String, dynamic>> homeApprovalFixtures(SeedGraph graph) {
  final random = graph.random('home-approvals');
  final members = graph.members
      .where((m) => m.role == WorkspaceRole.member && m.id != SeedGraph.meId)
      .toList();
  if (members.isEmpty) return const [];
  return [
    for (var i = 0; i < 6; i++)
      _approval(graph, i, members[(i * 3) % members.length], random.nextInt(9)),
  ];
}

Map<String, dynamic> _approval(
  SeedGraph graph,
  int index,
  SeedMember member,
  int roll,
) {
  final leave = index.isEven;
  final start = graph.daysAhead(roll % 5);
  return {
    'Id': index + 1,
    'Kind': leave ? 'Leave' : 'Expense',
    'MemberId': member.id,
    'MemberName': member.name.split(' ').first,
    'MemberNameBn': member.nameBn.split(' ').first,
    'Status': 'Pending',
    if (leave) 'From': jsonUtc(start),
    if (leave) 'To': jsonUtc(start.add(Duration(days: roll % 3))),
    if (!leave) 'Amount': 350 + roll * 250,
  };
}
