import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';

List<Map<String, dynamic>> syncMetaFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'LastSyncAt': AppDateUtils.toApiUtc(
      graph.anchor.subtract(const Duration(minutes: 2)),
    ),
    'DataBytes': 38 * megabyte + graph.leads.length * 9000,
    'CacheBytes': 112 * megabyte,
  },
];

List<Map<String, dynamic>> outboxFixtures(SeedGraph graph) {
  if (graph.leads.length < 3) return const [];
  final lead = graph.leads[2];
  final other = graph.leads[5 % graph.leads.length];
  final contact = graph.contact(other.contactId);
  DateTime at(int minutes) => graph.anchor.subtract(Duration(minutes: minutes));
  return [
    {
      'Id': 1,
      'Entity': 'CallLog',
      'Title': '${graph.company(lead.companyId).name} · ১২ মিনিট কল',
      'Operation': 'Create',
      'CreatedAt': AppDateUtils.toApiUtc(at(26)),
    },
    {
      'Id': 2,
      'Entity': 'Lead',
      'Title': '${lead.title} → Interested',
      'Operation': 'Update',
      'CreatedAt': AppDateUtils.toApiUtc(at(18)),
    },
    {
      'Id': 3,
      'Entity': 'Contact',
      'Title': '${contact.name} · ${contact.phone}',
      'Operation': 'Update',
      'CreatedAt': AppDateUtils.toApiUtc(at(9)),
      'Rejects': 'This number is already saved for another contact',
    },
  ];
}

/// Two leads changed offline that were also edited on the web: one deal
/// value, and a stage plus note.
List<Map<String, dynamic>> conflictFixtures(SeedGraph graph) {
  if (graph.leads.length < 2) return const [];
  final me = graph.me;
  final web = graph.members.firstWhere(
    (m) => m.role == WorkspaceRole.teamLead,
    orElse: () => me,
  );
  final first = graph.leads.first;
  final second = graph.leads[1];
  String at(int minutesAgo) => AppDateUtils.toApiUtc(
    graph.anchor.subtract(Duration(minutes: minutesAgo)),
  );
  Map<String, dynamic> version(Object value, String time, String by) => {
    'Value': value,
    'At': time,
    'By': by,
  };
  Map<String, dynamic> stage(int id, String time, String by) {
    final (_, name, nameBn, _) = SeedGraph.stages.firstWhere((s) => s.$1 == id);
    return {...version(id, time, by), 'Name': name, 'NameBn': nameBn};
  }

  return [
    {
      'Id': 1,
      'Entity': 'Lead',
      'EntityId': first.id,
      'Title': first.title,
      'Fields': [
        {
          'Field': 'Value',
          'Name': 'Deal value',
          'NameBn': 'সম্ভাব্য মূল্য',
          'Kind': 'Money',
          'Local': version(first.value + 30000, at(40), me.name),
          'Server': version(first.value, at(55), web.name),
        },
      ],
    },
    {
      'Id': 2,
      'Entity': 'Lead',
      'EntityId': second.id,
      'Title': second.title,
      'Fields': [
        {
          'Field': 'StageId',
          'Name': 'Stage',
          'NameBn': 'ধাপ',
          'Kind': 'Stage',
          'Local': stage(3, at(180), me.name),
          'Server': stage(4, at(205), web.name),
        },
        {
          'Field': 'Note',
          'Name': 'Note',
          'NameBn': 'নোট',
          'Kind': 'Text',
          'Local': version(
            'Rooftop 1,800 sq ft. ৫kW চায়, net metering নিয়ে প্রশ্ন আছে।',
            at(180),
            me.name,
          ),
          'Server': version(
            'Wants 5kW hybrid with battery. Quotation পাঠানো হবে কাল।',
            at(205),
            web.name,
          ),
        },
      ],
    },
  ];
}
