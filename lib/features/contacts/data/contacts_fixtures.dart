import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// Industries the company form and filters offer: English, Bangla.
const List<(String, String)> industryNames = [
  ('Textile', 'টেক্সটাইল'),
  ('Electronics', 'ইলেকট্রনিক্স'),
  ('Pharma', 'ফার্মা'),
  ('Food', 'খাদ্য'),
  ('Construction', 'নির্মাণ'),
  ('Retail', 'খুচরা ব্যবসা'),
  ('Agro', 'এগ্রো'),
  ('Furniture', 'আসবাবপত্র'),
  ('Healthcare', 'স্বাস্থ্যসেবা'),
  ('Printing', 'প্রিন্টিং'),
  ('Trading', 'ট্রেডিং'),
  ('Manufacturing', 'ম্যানুফ্যাকচারিং'),
];

String? industryBn(String? name) {
  for (final (en, bn) in industryNames) {
    if (en == name) return bn;
  }
  return null;
}

String? areaBn(String? name) {
  for (final area in SeedGraph.areas) {
    if (area.name == name) return area.nameBn;
  }
  return null;
}

SeedArea? areaNamed(String? name) {
  for (final area in SeedGraph.areas) {
    if (area.name == name) return area;
  }
  return null;
}

const List<String> _roads = [
  'Road 7, Block C',
  'Lane 4, Sector 11',
  'House 23, Road 12',
  'Plot 5, Section 2',
  'Holding 118, Main Road',
  'Level 4, Rahman Tower',
  'Shop 14, Market Complex',
  'House 9/A, Road 3',
];

const List<String> _companyNotes = [
  'Factory roof about 12,000 sq ft — net metering চান।',
  'Load shedding এ জেনারেটর খরচ বেশি, solar backup খুঁজছেন।',
  'Owner decides, purchase manager compares 3 quotations.',
  'বছরে একবার AMC চায়, payment 30 days credit.',
  'Prefers bKash for small payments, bank for big orders.',
  'নতুন শাখা খুলছে Q4 এ, আরেকটা inverter লাগবে।',
];

const List<String> _companyTags = [
  'Rooftop',
  'Net metering',
  'AMC',
  'Factory',
  'Showroom',
  'Repeat buyer',
  'Government tender',
];

const List<String> _contactNotes = [
  'সকাল ১১টার পর কল দিলে ধরেন।',
  'Prefers WhatsApp for quotations.',
  'Decision নেন MD sir এর সাথে কথা বলে।',
  'Friday off, Saturday office খোলা।',
  'Asked for a site survey before pricing.',
];

const List<String> _homeAddresses = [
  'Mirpur DOHS',
  'Uttara Sector 7',
  'Dhanmondi 27',
  'Banani Road 11',
  'Bashundhara R/A, Block D',
  'Mohammadpur, Tajmahal Road',
];

/// People who are not at any company yet: name, source.
const List<(String, String)> _independentPeople = [
  ('Rahima Begum', 'Facebook'),
  ('Abdur Rahim', 'Referral'),
  ('Shafiqul Alam', 'Walk-in'),
  ('Mousumi Akter', 'WhatsApp'),
  ('Kabir Hossain', 'Visiting card'),
  ('Nusrat Jahan', 'Website'),
  ('Rubel Mia', 'Phone call'),
  ('Tahmina Haque', 'Facebook'),
  ('Anwar Hossain', 'Referral'),
  ('Shamim Reza', 'Visit'),
];

String _phone(Random random) {
  const prefixes = ['13', '14', '15', '16', '17', '18', '19'];
  final body = 10000000 + random.nextInt(89999999);
  return '+880${prefixes[random.nextInt(prefixes.length)]}$body';
}

SeedMember _ownerOf(SeedGraph graph, int companyId, Random random) {
  for (final lead in graph.leads) {
    if (lead.companyId == companyId) return graph.member(lead.ownerId);
  }
  return graph.members[random.nextInt(graph.members.length)];
}

/// Companies as the server stores them. Counts, totals and the customer flag
/// are worked out when served.
List<Map<String, dynamic>> companyFixtures(SeedGraph graph) {
  final random = graph.random('companies');
  return [
    for (final company in graph.companies)
      _company(graph, company, random, _ownerOf(graph, company.id, random)),
  ];
}

Map<String, dynamic> _company(
  SeedGraph graph,
  SeedCompany company,
  Random random,
  SeedMember owner,
) {
  final hasCredit = random.nextInt(3) == 0;
  return {
    'Id': company.id,
    'Code': 'PR-${company.id.toString().padLeft(4, '0')}',
    'Name': company.name,
    'IndustryType': company.industry,
    'ZoneName': company.area.name,
    'ContactNumber': company.phone,
    if (random.nextBool())
      'Email':
          'info@${company.name.toLowerCase().replaceAll(RegExp('[^a-z]'), '')}.com',
    'WebsiteProspect': ?company.website,
    'Latitude': company.area.lat + (random.nextDouble() - 0.5) / 100,
    'Longitude': company.area.lng + (random.nextDouble() - 0.5) / 100,
    'Addresses': [
      {
        'Type': 'Present',
        'Address':
            '${_roads[random.nextInt(_roads.length)]}, ${company.area.name}, Dhaka',
        if (random.nextBool()) 'ZipCode': '12${random.nextInt(90) + 10}',
      },
    ],
    if (random.nextInt(3) > 0)
      'Note': _companyNotes[random.nextInt(_companyNotes.length)],
    'Tags': [
      for (var i = 0; i < random.nextInt(3); i++)
        _companyTags[(company.id + i * 3) % _companyTags.length],
    ],
    'CreatedOn': jsonUtc(graph.daysAgo(60 + random.nextInt(640))),
    'AssignedTo': {'Id': owner.id, 'Name': owner.name},
    if (hasCredit) 'CreditLimit': (random.nextInt(8) + 1) * 50000,
    if (hasCredit) 'CreditDays': [15, 30, 45][random.nextInt(3)],
  };
}

/// Concern persons from the shared graph plus a few independent people.
List<Map<String, dynamic>> contactFixtures(SeedGraph graph) {
  final random = graph.random('contacts');
  final rows = <Map<String, dynamic>>[
    for (final contact in graph.contacts) _contact(graph, contact, random),
  ];
  var id = graph.contacts.length;
  for (final (name, source) in _independentPeople) {
    id++;
    final creator = graph.members[random.nextInt(graph.members.length)];
    rows.add({
      'Id': id,
      'Name': name,
      'IsPrimary': false,
      'Mobiles': [_phone(random)],
      'Emails': const <String>[],
      'Source': source,
      if (random.nextBool())
        'Note': _contactNotes[random.nextInt(_contactNotes.length)],
      'Tags': const <String>[],
      'CreatedOn': jsonUtc(graph.daysAgo(random.nextInt(45))),
      'CreatedBy': {'Id': creator.id, 'Name': creator.name},
    });
  }
  return rows;
}

Map<String, dynamic> _contact(
  SeedGraph graph,
  SeedContact contact,
  Random random,
) {
  final creator = _ownerOf(graph, contact.companyId, random);
  final birthday = random.nextInt(4) == 0
      ? DateTime(1975 + random.nextInt(25), random.nextInt(12) + 1, 12)
      : null;
  return {
    'Id': contact.id,
    'Name': contact.name,
    'Designation': contact.designation,
    'ProspectId': contact.companyId,
    'IsPrimary': contact.isPrimary,
    'Mobiles': [contact.phone, if (random.nextInt(5) == 0) _phone(random)],
    'Emails': [?contact.email],
    if (random.nextInt(3) == 0)
      'Address': _homeAddresses[random.nextInt(_homeAddresses.length)],
    'DateOfBirth': jsonUtc(birthday),
    if (random.nextInt(3) == 0)
      'Note': _contactNotes[random.nextInt(_contactNotes.length)],
    'Tags': [if (contact.isPrimary) 'Decision maker'],
    'Source': SeedGraph.sources[random.nextInt(SeedGraph.sources.length)],
    'CreatedOn': jsonUtc(graph.daysAgo(random.nextInt(400))),
    'CreatedBy': {'Id': creator.id, 'Name': creator.name},
  }..removeWhere((_, value) => value == null);
}

String _leadStatus(SeedLead lead) => switch (lead.stageId) {
  5 => 'Won',
  6 => 'Lost',
  _ => 'Open',
};

/// A lead from the shared graph as a contact or company lists it.
Map<String, dynamic> linkedLeadJson(SeedGraph graph, SeedLead lead) {
  final stage = SeedGraph.stages.firstWhere((s) => s.$1 == lead.stageId);
  return {
    'Id': lead.id,
    'Title': lead.title,
    'Stage': {'Name': stage.$2, 'NameBn': stage.$3},
    'Status': _leadStatus(lead),
    'Value': lead.value,
    'OwnerName': graph.member(lead.ownerId).name,
    'UpdatedOn': jsonUtc(graph.daysAgo(lead.lastTouchDaysAgo, hour: 15)),
  };
}

const List<String> _callNotes = [
  'Rooftop measurement এর জন্য সময় চেয়েছেন।',
  'Asked for a revised price on the 5kW inverter.',
  'বাজেট approve হয়নি, next week আবার কল।',
  'Confirmed delivery address and gate pass.',
  'Wants battery backup for 6 hours.',
];

const List<String> _messageNotes = [
  'Sent the quotation PDF.',
  '“ডেলিভারি কবে?” — replied with date.',
  'Shared site photos of the roof.',
  'Payment reminder sent.',
];

/// Calls, messages, visits and notes with each seeded contact, newest first.
List<Map<String, dynamic>> contactActivityFixtures(SeedGraph graph) => [
  for (
    var id = 1;
    id <= graph.contacts.length + _independentPeople.length;
    id++
  )
    ..._activityOf(graph, id),
];

List<Map<String, dynamic>> _activityOf(SeedGraph graph, int contactId) {
  final random = graph.random('activity/$contactId');
  final leads = graph.leads.where((l) => l.contactId == contactId).toList();
  final count = 2 + random.nextInt(5);
  var daysAgo = random.nextInt(3);
  final rows = <Map<String, dynamic>>[];
  for (var i = 0; i < count; i++) {
    final type = const [
      'Call',
      'Call',
      'WhatsApp',
      'Visit',
      'Note',
      'Sms',
      'Email',
    ][random.nextInt(7)];
    final lead = leads.isEmpty ? null : leads[random.nextInt(leads.length)];
    final by = lead == null
        ? graph.members[random.nextInt(graph.members.length)]
        : graph.member(lead.ownerId);
    rows.add(
      {
        'Id': contactId * 100 + i,
        'ContactId': contactId,
        'Type': type,
        'On': jsonUtc(
          graph.daysAgo(
            daysAgo,
            hour: 9 + random.nextInt(9),
            minute: random.nextInt(60),
          ),
        ),
        'Note': switch (type) {
          'Call' => _callNotes[random.nextInt(_callNotes.length)],
          'Visit' => 'Site survey and roof check.',
          _ => _messageNotes[random.nextInt(_messageNotes.length)],
        },
        'ByName': by.name,
        'LeadId': lead?.id,
        if (type == 'Call') 'DurationMinutes': 1 + random.nextInt(12),
        if (type == 'Visit') 'DurationMinutes': 20 + random.nextInt(60),
      }..removeWhere((_, value) => value == null),
    );
    daysAgo += 1 + random.nextInt(9);
  }
  return rows;
}
