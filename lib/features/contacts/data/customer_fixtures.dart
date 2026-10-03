import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/data/contacts_fixtures.dart';

const List<String> _paymentMethods = [
  'bKash',
  'Cash',
  'Bank transfer',
  'Nagad',
];

const List<String> _visitPurposes = [
  'office',
  'site survey',
  'factory',
  'installation check',
];

/// A customer's money and documents worked out from the shared graph: every
/// won lead became a quotation, an order and an invoice; payments against
/// the invoices are the collections. [summary] totals agree with the lists.
class CustomerLedger {
  CustomerLedger._(this.summary);

  final Map<String, dynamic> summary;

  int get totalSales => summary['TotalSales'] as int;
  int get outstanding => summary['Outstanding'] as int;
  bool get isClient => (summary['Invoices'] as List).isNotEmpty;

  DateTime? get clientSince {
    final invoices = summary['Invoices'] as List;
    if (invoices.isEmpty) return null;
    return jsonDate((invoices.last as Map<String, dynamic>)['On']);
  }

  factory CustomerLedger.of(SeedGraph graph, int companyId, String name) {
    final random = graph.random('ledger/$companyId');
    final today = graph.daysAgo(0, hour: 0);
    final leads =
        graph.leads.where((lead) => lead.companyId == companyId).toList()
          ..sort((a, b) => a.createdDaysAgo.compareTo(b.createdDaysAgo));
    final quotations = <Map<String, dynamic>>[];
    final orders = <Map<String, dynamic>>[];
    final invoices = <Map<String, dynamic>>[];
    final events = <Map<String, dynamic>>[];

    for (final lead in leads) {
      final started = max(lead.createdDaysAgo, 8);
      if (lead.stageId == 4 || lead.stageId == 5) {
        final quotedDaysAgo = started - 2;
        quotations.add({
          'Id': lead.id,
          'Number': 'Q-${1000 + lead.id}',
          'Amount': lead.value,
          'On': jsonUtc(graph.daysAgo(quotedDaysAgo, hour: 12)),
          'Status': lead.stageId == 5 ? 'Accepted' : 'Sent',
          'LeadId': lead.id,
        });
        events.add({
          'Kind': 'Quotation',
          'On': jsonUtc(graph.daysAgo(quotedDaysAgo, hour: 12)),
          'Number': 'Q-${1000 + lead.id}',
          'Amount': lead.value,
          'RefId': lead.id,
          'ByName': graph.member(lead.ownerId).name,
        });
      }
      if (lead.stageId != 5) continue;
      _addSale(
        graph: graph,
        random: random,
        lead: lead,
        soldDaysAgo: started ~/ 2,
        today: today,
        orders: orders,
        invoices: invoices,
        events: events,
      );
    }

    final visitCount = _addTouches(graph, random, companyId, leads, events);
    events.sort((a, b) => (b['On'] as String).compareTo(a['On'] as String));
    invoices.sort((a, b) => (b['On'] as String).compareTo(a['On'] as String));

    var total = 0;
    var collected = 0;
    var overdue = 0;
    for (final invoice in invoices) {
      final amount = invoice['Amount'] as int;
      final paid = invoice['Paid'] as int;
      total += amount;
      collected += paid;
      final due = jsonDate(invoice['DueOn']);
      if (due != null && due.isBefore(today)) overdue += amount - paid;
    }

    return CustomerLedger._({
      'ProspectId': companyId,
      'ProspectName': name,
      'TotalSales': total,
      'Collected': collected,
      'Outstanding': total - collected,
      'Overdue': overdue,
      'OpenDealValue': leads
          .where((lead) => lead.isOpen)
          .fold<int>(0, (sum, lead) => sum + lead.value),
      'Leads': [for (final lead in leads) linkedLeadJson(graph, lead)],
      'Quotations': quotations.reversed.toList(),
      'Orders': orders.reversed.toList(),
      'Invoices': invoices,
      'VisitCount': visitCount,
      'Events': events,
    });
  }

  static void _addSale({
    required SeedGraph graph,
    required Random random,
    required SeedLead lead,
    required int soldDaysAgo,
    required DateTime today,
    required List<Map<String, dynamic>> orders,
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> events,
  }) {
    final owner = graph.member(lead.ownerId).name;
    final invoicedOn = graph.daysAgo(soldDaysAgo, hour: 11);
    final roll = random.nextInt(100);
    final share = roll < 55
        ? 100
        : roll < 85
        ? 40 + random.nextInt(40)
        : 0;
    final paid = (lead.value * share / 100).round() ~/ 100 * 100;

    orders.add({
      'Id': lead.id,
      'Number': 'SO-${200 + lead.id}',
      'Amount': lead.value,
      'On': jsonUtc(graph.daysAgo(soldDaysAgo + 1, hour: 16)),
      'Status': soldDaysAgo > 6 ? 'Delivered' : 'Processing',
      'LeadId': lead.id,
    });
    invoices.add({
      'Id': lead.id,
      'Number': 'INV-${lead.id}',
      'Amount': lead.value,
      'Paid': paid,
      'On': jsonUtc(invoicedOn),
      'DueOn': jsonUtc(invoicedOn.add(const Duration(days: 30))),
      'Status': paid >= lead.value
          ? 'Paid'
          : paid > 0
          ? 'Partial'
          : 'Unpaid',
      'LeadId': lead.id,
    });
    events
      ..add({
        'Kind': 'Order',
        'On': jsonUtc(graph.daysAgo(soldDaysAgo + 1, hour: 16)),
        'Number': 'SO-${200 + lead.id}',
        'Amount': lead.value,
        'RefId': lead.id,
        'ByName': owner,
      })
      ..add({
        'Kind': 'Invoice',
        'On': jsonUtc(invoicedOn),
        'Number': 'INV-${lead.id}',
        'Amount': lead.value,
        'RefId': lead.id,
        'ByName': owner,
      });
    if (soldDaysAgo > 6) {
      events.add({
        'Kind': 'Delivery',
        'On': jsonUtc(graph.daysAgo(soldDaysAgo - 3, hour: 14)),
        'Number': 'SO-${200 + lead.id}',
        'RefId': lead.id,
        'ByName': owner,
      });
    }

    final instalments = paid == 0 ? 0 : (paid >= 100000 ? 2 : 1);
    var left = paid;
    for (var i = 0; i < instalments; i++) {
      final amount = i == instalments - 1 ? left : left ~/ 200 * 100;
      left -= amount;
      final paidDaysAgo = max(0, soldDaysAgo - 5 - i * 10);
      events.add({
        'Kind': 'Collection',
        'On': jsonUtc(graph.daysAgo(paidDaysAgo, hour: 13)),
        'Number': 'R-${lead.id * 10 + i}',
        'Amount': amount,
        'Method': _paymentMethods[random.nextInt(_paymentMethods.length)],
        'Note': 'INV-${lead.id}',
        'RefId': lead.id * 10 + i,
        'ByName': owner,
      });
    }
  }

  static int _addTouches(
    SeedGraph graph,
    Random random,
    int companyId,
    List<SeedLead> leads,
    List<Map<String, dynamic>> events,
  ) {
    final people = [for (final lead in leads) graph.member(lead.ownerId)];
    if (people.isEmpty) people.add(graph.me);
    final visits = leads.isEmpty ? 0 : 1 + random.nextInt(3);
    for (var i = 0; i < visits; i++) {
      events.add({
        'Kind': 'Visit',
        'On': jsonUtc(graph.daysAgo(3 + random.nextInt(60), hour: 11)),
        'Note': _visitPurposes[random.nextInt(_visitPurposes.length)],
        'ByName': people[random.nextInt(people.length)].name,
        'DurationMinutes': 20 + random.nextInt(60),
      });
    }
    final talks = 1 + random.nextInt(3);
    for (var i = 0; i < talks; i++) {
      final whatsApp = random.nextBool();
      events.add({
        'Kind': whatsApp ? 'WhatsApp' : 'Call',
        'On': jsonUtc(
          graph.daysAgo(random.nextInt(20), hour: 10 + random.nextInt(8)),
        ),
        'Note': whatsApp
            ? '“ডেলিভারি কবে?” — replied'
            : 'Discussed battery backup hours',
        'ByName': people[random.nextInt(people.length)].name,
        if (whatsApp) 'Count': 2 + random.nextInt(5),
        if (!whatsApp) 'DurationMinutes': 2 + random.nextInt(10),
      });
    }
    return visits;
  }
}

/// The customer's documents: one per quotation, invoice and receipt in the
/// ledger, plus agreements and visit photos.
List<Map<String, dynamic>> customerDocumentFixtures(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  var id = 0;
  for (final company in graph.companies) {
    final ledger = CustomerLedger.of(graph, company.id, company.name).summary;
    final random = graph.random('documents/${company.id}');
    for (final quote in ledger['Quotations'] as List) {
      final row = quote as Map<String, dynamic>;
      rows.add({
        'Id': ++id,
        'ProspectId': company.id,
        'Title': row['Number'],
        'FileName': '${row['Number']}.pdf',
        'Category': 'Quotation',
        'UploadedOn': row['On'],
        'SizeInKb': 180 + random.nextInt(200),
        'Amount': row['Amount'],
        'Viewed': random.nextBool(),
      });
    }
    for (final invoice in ledger['Invoices'] as List) {
      final row = invoice as Map<String, dynamic>;
      rows.add({
        'Id': ++id,
        'ProspectId': company.id,
        'Title': row['Number'],
        'FileName': '${row['Number']}.pdf',
        'Category': 'Invoice',
        'UploadedOn': row['On'],
        'SizeInKb': 140 + random.nextInt(120),
        'Amount': row['Amount'],
      });
    }
    for (final event in ledger['Events'] as List) {
      final row = event as Map<String, dynamic>;
      if (row['Kind'] == 'Collection') {
        rows.add({
          'Id': ++id,
          'ProspectId': company.id,
          'Title': row['Number'],
          'FileName': '${row['Number']}.pdf',
          'Category': 'Receipt',
          'UploadedOn': row['On'],
          'SizeInKb': 60 + random.nextInt(40),
          'Amount': row['Amount'],
          'Source': 'Sms',
        });
      }
      if (row['Kind'] == 'Visit' && random.nextBool()) {
        rows.add({
          'Id': ++id,
          'ProspectId': company.id,
          'Title': 'Site photo',
          'FileName': 'site-${company.id}-$id.png',
          'Category': 'Photo',
          'UploadedOn': row['On'],
          'SizeInKb': 900 + random.nextInt(1400),
          'UploadedBy': row['ByName'],
          'Source': 'Visit',
        });
      }
    }
    if ((ledger['Invoices'] as List).isNotEmpty) {
      final year = graph.anchor.year;
      rows.add({
        'Id': ++id,
        'ProspectId': company.id,
        'Title': 'Supply agreement $year',
        'FileName': 'supply-agreement-$year.pdf',
        'Category': 'Agreement',
        'UploadedOn': jsonUtc(graph.daysAgo(30 + random.nextInt(90))),
        'SizeInKb': 1800 + random.nextInt(800),
        'UploadedBy': graph
            .member(_ownerId(graph, company.id) ?? SeedGraph.meId)
            .name,
      });
    }
  }
  return rows;
}

int? _ownerId(SeedGraph graph, int companyId) {
  for (final lead in graph.leads) {
    if (lead.companyId == companyId) return lead.ownerId;
  }
  return null;
}

/// Industries and areas for the company filters and form.
Map<String, dynamic> companyLookupsFixture() => {
  'Industries': [
    for (final (en, bn) in industryNames) {'Name': en, 'NameBn': bn},
  ],
  'Zones': [
    for (final area in SeedGraph.areas)
      {'Name': area.name, 'NameBn': area.nameBn},
  ],
};
