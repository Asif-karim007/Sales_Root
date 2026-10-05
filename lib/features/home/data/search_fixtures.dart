import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// The server's search index over the shared graph: one row per lead,
/// contact and company, with the words each one is found by.
List<Map<String, dynamic>> searchIndexFixtures(SeedGraph graph) => [
  for (final lead in graph.leads) _lead(graph, lead),
  for (final contact in graph.contacts) _contact(graph, contact),
  for (final company in graph.companies) _company(company),
];

Map<String, dynamic> _lead(SeedGraph graph, SeedLead lead) {
  final company = graph.company(lead.companyId);
  final contact = graph.contact(lead.contactId);
  final stage = SeedGraph.stages.firstWhere((s) => s.$1 == lead.stageId);
  return {
    'Id': lead.id,
    'Kind': 'Leads',
    'Title': lead.title,
    'Subtitle': contact.name,
    'Stage': {'Name': stage.$2, 'NameBn': stage.$3},
    'Value': lead.value,
    'Keywords': [
      company.name,
      contact.name,
      contact.phone,
      lead.source,
      company.area.name,
      company.area.nameBn,
    ].join(' '),
  };
}

Map<String, dynamic> _contact(SeedGraph graph, SeedContact contact) {
  final company = graph.company(contact.companyId);
  return {
    'Id': contact.id,
    'Kind': 'Contacts',
    'Title': contact.name,
    'Subtitle': '${contact.designation} · ${company.name}',
    'Keywords': [
      company.name,
      contact.phone,
      contact.email ?? '',
      company.area.nameBn,
    ].join(' '),
  };
}

Map<String, dynamic> _company(SeedCompany company) => {
  'Id': company.id,
  'Kind': 'Companies',
  'Title': company.name,
  'Subtitle': '${company.industry} · ${company.area.name}',
  'Keywords': [
    company.phone,
    company.website ?? '',
    company.area.name,
    company.area.nameBn,
  ].join(' '),
};

const _taskNotes = [
  'discuss quotation',
  'কোটেশন নিয়ে কথা',
  'site survey for rooftop',
  'ইনভার্টার ডেমো দেখাতে হবে',
  'price negotiation',
  'payment follow-up',
];

const _ownTasks = [
  'Submit weekly visit report',
  'Collect cheque from accounts',
  'Team meeting — monthly target',
  'Update panel price list',
];

/// The signed-in user's tasks as the index finds them: one per open lead,
/// titled by its company, plus a few of their own.
List<Map<String, dynamic>> searchTaskFixtures(SeedGraph graph) {
  final random = graph.random('search-tasks');
  final leads = graph.leadsOf(SeedGraph.meId).where((l) => l.isOpen);
  final rows = <Map<String, dynamic>>[];
  for (final lead in leads) {
    final offset = random.nextInt(8) - 3;
    rows.add({
      'Id': rows.length + 1,
      'Kind': 'Tasks',
      'Title': graph.company(lead.companyId).name,
      'Subtitle': _taskNotes[random.nextInt(_taskNotes.length)],
      'DueAt': jsonUtc(graph.daysAhead(offset, hour: 9 + random.nextInt(9))),
      'IsDone': offset < 0 && random.nextInt(3) == 0,
      'Keywords': lead.title,
    });
  }
  for (final title in _ownTasks) {
    rows.add({
      'Id': rows.length + 1,
      'Kind': 'Tasks',
      'Title': title,
      'DueAt': jsonUtc(graph.daysAhead(random.nextInt(3), hour: 15)),
      'IsDone': false,
      'Keywords': title,
    });
  }
  return rows;
}
