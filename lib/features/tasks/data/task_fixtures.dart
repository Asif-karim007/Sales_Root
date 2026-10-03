import 'dart:math';

import 'package:collection/collection.dart';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/models/task.dart';

/// Server-shaped task rows for the workspace: the prototype's own day for the
/// user, then one to three tasks per lead for its owner, then the user's own
/// chores. Computed fields (`IsOverdue`, `DaysUntilDue`, `CanEdit`…) are added
/// when a row is served.
List<Map<String, dynamic>> taskFixtures(SeedGraph graph) {
  final random = graph.random('tasks');
  final rows = <Map<String, dynamic>>[
    ..._prototypeDay(graph),
    for (final lead in graph.leads) ..._leadTasks(graph, lead, random),
    ..._ownTasks(graph),
  ];
  return [
    for (var i = 0; i < rows.length; i++) {...rows[i], 'Id': i + 1},
  ];
}

Map<String, dynamic> _person(SeedMember member) => {
  'Id': member.id,
  'Name': member.name,
  'NameBn': member.nameBn,
};

Map<String, dynamic> _status(bool done) => {
  'Id': done ? TaskStatusRef.doneId : TaskStatusRef.openId,
  'Name': done ? 'Done' : 'To do',
  'IsDone': done,
};

Map<String, dynamic> _row(
  SeedGraph graph, {
  required String title,
  required TaskType type,
  required DateTime due,
  required SeedMember assignee,
  SeedMember? creator,
  SeedLead? lead,
  String? description,
  String? notes,
  int? amount,
  int? reminder = 30,
  bool done = false,
  int createdDaysBefore = 3,
}) => {
  'Title': title,
  'TypeId': type.id,
  'Description': description,
  'Status': _status(done),
  'DueDate': jsonUtc(due),
  'AssignedTo': _person(assignee),
  'CreatedBy': _person(creator ?? assignee),
  'CreatedOn': jsonUtc(due.subtract(Duration(days: createdDaysBefore))),
  'CompletedOn': done
      ? jsonUtc(due.add(Duration(minutes: 20 + due.minute)))
      : null,
  'Lead': lead == null ? null : {'Id': lead.id, 'Name': lead.title},
  'Amount': amount,
  'Notes': notes,
  'ReminderMinutes': reminder,
}..removeWhere((_, value) => value == null);

SeedLead? _leadOf(SeedGraph graph, String company) {
  final match = graph.companies.firstWhereOrNull((c) => c.name == company);
  if (match == null) return null;
  return graph.leads.firstWhereOrNull((l) => l.companyId == match.id);
}

List<Map<String, dynamic>> _prototypeDay(SeedGraph graph) {
  final me = graph.me;
  final sajib = graph.contacts.firstWhereOrNull(
    (c) => c.name == 'Sajib Hossain',
  );
  final sajibLead = sajib == null
      ? null
      : graph.leads.firstWhereOrNull((l) => l.companyId == sajib.companyId);
  final karim = _leadOf(graph, 'Karim Textiles');
  final delta = _leadOf(graph, 'Delta Power');
  final meghna = _leadOf(graph, 'Meghna Group');
  final rahim = _leadOf(graph, 'Rahim Enterprise');
  final green = _leadOf(graph, 'Green Agro');
  return [
    _row(
      graph,
      title: 'Call Sajib Hossain',
      type: TaskType.followUp,
      due: graph.daysAgo(1, hour: 15),
      assignee: me,
      lead: sajibLead,
      description: 'Follow-up · no contact 3 days',
      notes: 'Rooftop 5kW-er quotation pathano hoyeche, kono reply nai.',
    ),
    _row(
      graph,
      title: 'Send Meghna Group quotation',
      type: TaskType.quotation,
      due: graph.daysAgo(2, hour: 12),
      assignee: me,
      lead: meghna,
      amount: 580000,
      description: 'Factory solar kit 10kW + installation',
    ),
    _row(
      graph,
      title: 'Call Karim Textiles',
      type: TaskType.call,
      due: graph.daysAgo(0, hour: 11),
      assignee: me,
      lead: karim,
      description: 'Discuss quotation',
      notes:
          'Discuss quotation #Q-0042; confirm whether a 5% discount is '
          'possible.',
    ),
    _row(
      graph,
      title: 'Visit Delta Power',
      type: TaskType.visit,
      due: graph.daysAgo(0, hour: 14, minute: 30),
      assignee: me,
      lead: delta,
      description: 'Banani · with samples',
      notes: '550W panel আর 5kW hybrid inverter-এর স্যাম্পল নিয়ে যেতে হবে।',
      reminder: 60,
    ),
    _row(
      graph,
      title: 'Collect from Rahim Enterprise',
      type: TaskType.collection,
      due: graph.daysAgo(0, hour: 16),
      assignee: me,
      lead: rahim,
      amount: 50000,
      description: '2nd instalment',
    ),
    _row(
      graph,
      title: 'Morning report',
      type: TaskType.own,
      due: graph.daysAgo(0, hour: 9),
      assignee: me,
      description: 'Own task',
      reminder: null,
      done: true,
      createdDaysBefore: 0,
    ),
    _row(
      graph,
      title: 'Follow up Green Agro',
      type: TaskType.followUp,
      due: graph.daysAhead(1, hour: 10),
      assignee: me,
      lead: green,
      description: 'Share price',
      notes: 'Solar pump 2HP-er dam janate hobe, 3 piece lagbe.',
    ),
  ];
}

List<Map<String, dynamic>> _leadTasks(
  SeedGraph graph,
  SeedLead lead,
  Random random,
) {
  final owner = graph.members.firstWhereOrNull((m) => m.id == lead.ownerId);
  if (owner == null) return const [];
  final mine = owner.id == SeedGraph.meId;
  final count = lead.isOpen
      ? (mine ? 2 : 1) + random.nextInt(2)
      : random.nextInt(2);
  final company = graph.company(lead.companyId);
  final contact = graph.contact(lead.contactId);
  final manager = owner.managerId == null
      ? null
      : graph.members.firstWhereOrNull((m) => m.id == owner.managerId);
  return [
    for (var i = 0; i < count; i++)
      _leadTask(graph, lead, company, contact, owner, manager, random, i),
  ];
}

Map<String, dynamic> _leadTask(
  SeedGraph graph,
  SeedLead lead,
  SeedCompany company,
  SeedContact contact,
  SeedMember owner,
  SeedMember? manager,
  Random random,
  int index,
) {
  final type = lead.isOpen
      ? _openTypes[random.nextInt(_openTypes.length)]
      : (lead.stageId == 5 ? TaskType.collection : TaskType.followUp);
  final offset = lead.isOpen
      ? random.nextInt(40) - 22 + index * 3
      : -(random.nextInt(30) + 2);
  final due = offset < 0
      ? graph.daysAgo(
          -offset,
          hour: 9 + random.nextInt(9),
          minute: 30 * random.nextInt(2),
        )
      : graph.daysAhead(
          offset,
          hour: 9 + random.nextInt(9),
          minute: 30 * random.nextInt(2),
        );
  final done = offset < 0
      ? random.nextInt(10) < 7
      : offset == 0 && random.nextBool();
  final assignedByManager = manager != null && random.nextInt(4) == 0;
  return _row(
    graph,
    title: _title(type, company, contact, random),
    type: type,
    due: due,
    assignee: owner,
    creator: assignedByManager ? manager : owner,
    lead: lead,
    description: _description(type, company, random),
    notes: random.nextInt(3) == 0
        ? _notes[random.nextInt(_notes.length)]
        : null,
    amount: switch (type) {
      TaskType.quotation => lead.value,
      TaskType.collection =>
        (lead.value * (2 + random.nextInt(4)) / 10).round(),
      _ => null,
    },
    reminder: random.nextInt(3) == 0 ? null : _reminders[random.nextInt(3)],
    done: done,
    createdDaysBefore: 1 + random.nextInt(6),
  );
}

String _title(
  TaskType type,
  SeedCompany company,
  SeedContact contact,
  Random random,
) => switch (type) {
  TaskType.call =>
    random.nextBool() ? 'Call ${company.name}' : '${contact.name}-কে কল',
  TaskType.visit => 'Visit ${company.name}',
  TaskType.followUp => 'Follow up ${company.name}',
  TaskType.meeting => 'Meeting with ${contact.name}',
  TaskType.quotation => 'Send ${company.name} quotation',
  TaskType.collection => 'Collect from ${company.name}',
  TaskType.own => company.name,
};

String _description(TaskType type, SeedCompany company, Random random) {
  final pool = switch (type) {
    TaskType.call => _callNotes,
    TaskType.visit => [
      for (final note in _visitNotes) '${company.area.name} · $note',
    ],
    TaskType.followUp => _followUpNotes,
    TaskType.meeting => _meetingNotes,
    TaskType.quotation => _quotationNotes,
    TaskType.collection => _collectionNotes,
    TaskType.own => const ['Own task'],
  };
  return pool[random.nextInt(pool.length)];
}

List<Map<String, dynamic>> _ownTasks(SeedGraph graph) {
  final me = graph.me;
  return [
    for (var day = 1; day <= 4; day++)
      _row(
        graph,
        title: 'Morning report',
        type: TaskType.own,
        due: graph.daysAgo(day, hour: 9),
        assignee: me,
        description: 'Own task',
        reminder: null,
        done: true,
        createdDaysBefore: 0,
      ),
    _row(
      graph,
      title: 'Update price list',
      type: TaskType.own,
      due: graph.daysAhead(2, hour: 17),
      assignee: me,
      description: 'New inverter rates from the supplier',
    ),
    _row(
      graph,
      title: 'Weekly pipeline review',
      type: TaskType.meeting,
      due: graph.daysAhead(4, hour: 11),
      assignee: me,
      description: 'Team meeting · office',
      reminder: 60,
    ),
    _row(
      graph,
      title: 'Submit conveyance bills',
      type: TaskType.own,
      due: graph.daysAgo(3, hour: 18),
      assignee: me,
      description: 'Own task',
      notes: 'সেপ্টেম্বরের রিকশা আর সিএনজি ভাড়া।',
    ),
    _row(
      graph,
      title: 'স্টক চেক — লিথিয়াম ব্যাটারি',
      type: TaskType.own,
      due: graph.daysAhead(6, hour: 10),
      assignee: me,
      description: 'Warehouse, Tejgaon',
    ),
  ];
}

const _openTypes = [
  TaskType.call,
  TaskType.call,
  TaskType.visit,
  TaskType.followUp,
  TaskType.followUp,
  TaskType.meeting,
  TaskType.quotation,
  TaskType.collection,
];

const _reminders = [15, 30, 60];

const _callNotes = [
  'Discuss quotation',
  'Confirm site survey date',
  'ইনভার্টার নিয়ে কথা',
  'Ask about net metering',
  'Payment follow-up',
  'Battery backup requirement',
];

const _visitNotes = [
  'with samples',
  'rooftop survey',
  'panel demo',
  'installation check',
];

const _followUpNotes = [
  'Share price',
  'No contact 3 days',
  'দাম জানাতে হবে',
  'Send battery spec sheet',
  'Waiting for MD approval',
];

const _meetingNotes = [
  '10kW rooftop plan with the factory manager',
  'AMC renewal',
  'Office-e demo, projector lagbe',
];

const _quotationNotes = [
  'Rooftop solar 10kW',
  'Hybrid inverter 5kW + battery',
  'Solar street lights × 20',
  'Factory solar kit + installation',
];

const _collectionNotes = [
  '2nd instalment',
  '১ম কিস্তি',
  'Final payment',
  'Advance against PO',
];

const _notes = [
  'Customer wants delivery before Eid.',
  'MD sir only free after 3pm.',
  'Roof is tin shed, check mounting structure.',
  'দাম একটু বেশি বলছে, ৩% ছাড় দেওয়া যায়।',
  'Bring the warranty card copy.',
  'Gate-e security ke phone dite hobe.',
];
