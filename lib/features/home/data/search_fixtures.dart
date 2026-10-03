import 'package:salesroot/core/fake/seed_graph.dart';

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
    'StageId': lead.stageId,
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
