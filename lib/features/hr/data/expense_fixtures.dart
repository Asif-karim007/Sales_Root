import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/models/expense.dart';

const int travelTypeId = 1;
const int mealsTypeId = 2;
const int entertainmentTypeId = 3;
const int mobileTypeId = 4;
const int otherTypeId = 5;

/// Above this, the owner approves after the first approver.
const double managerApprovalAbove = 2000;

const List<Map<String, dynamic>> expenseTypeRows = [
  {
    'Id': travelTypeId,
    'Code': 'Travel',
    'Name': 'Travel',
    'NameBn': 'যাতায়াত',
    'ReceiptRequiredAbove': 1000,
  },
  {
    'Id': mealsTypeId,
    'Code': 'Meals',
    'Name': 'Meals',
    'NameBn': 'খাবার',
    'ReceiptRequiredAbove': 500,
  },
  {
    'Id': entertainmentTypeId,
    'Code': 'Entertainment',
    'Name': 'Client entertainment',
    'NameBn': 'গ্রাহক আপ্যায়ন',
    'ReceiptRequiredAbove': 0,
  },
  {'Id': mobileTypeId, 'Code': 'Mobile', 'Name': 'Mobile', 'NameBn': 'মোবাইল'},
  {
    'Id': otherTypeId,
    'Code': 'Other',
    'Name': 'Other',
    'NameBn': 'অন্য',
    'ReceiptRequiredAbove': 1000,
  },
];

Map<String, dynamic> expenseTypeRow(int id) =>
    expenseTypeRows.firstWhere((row) => row['Id'] == id);

/// A visit the signed-in rep made, as the expense lookups return it. Any id
/// resolves, so a link from the visit screens always prefills.
Map<String, dynamic> expenseVisitRow(SeedGraph graph, int id) {
  final mine = graph.leadsOf(graph.me.id);
  final leads = mine.isEmpty ? graph.leads : mine;
  final company = leads.isEmpty
      ? graph.companies[(id - 1) % graph.companies.length]
      : graph.company(leads[(id - 1) % leads.length].companyId);
  final areas = SeedGraph.areas;
  return {
    'Id': id,
    'ProspectId': company.id,
    'ProspectName': company.name,
    'VisitedAt': jsonUtc(graph.daysAgo((id - 1) ~/ 2, hour: 10 + id % 7)),
    'StartLocation': areas[(id * 3) % areas.length].name,
    'EndLocation': company.area.name,
  };
}

Map<String, dynamic> expenseRow({
  required SeedGraph graph,
  required int id,
  required int employeeId,
  required int typeId,
  required double amount,
  required DateTime day,
  required ExpenseStage stage,
  String? description,
  String? from,
  String? to,
  int? prospectId,
  int? visitId,
  int personCount = 1,
  List<String> receipts = const [],
  String? note,
  int approvalStep = 1,
}) {
  final type = expenseTypeRow(typeId);
  final approver = approverOf(graph, employeeId);
  final decided =
      stage == ExpenseStage.approved ||
      stage == ExpenseStage.paid ||
      stage == ExpenseStage.rejected ||
      stage == ExpenseStage.returned;
  final prospect = prospectId == null
      ? null
      : graph.companies.where((c) => c.id == prospectId).firstOrNull;
  return {
    'Id': id,
    'Code': 'EXP${id.toString().padLeft(5, '0')}',
    'Title': type['Name'],
    'ClaimedTotal': amount,
    'WorkflowStatus': stage == ExpenseStage.paid ? 'approved' : stage.wire,
    'SettlementStatus': stage == ExpenseStage.paid ? 'paid' : 'unpaid',
    'PrimaryTypeId': typeId,
    'PrimaryTypeCode': type['Code'],
    'PrimaryType': type['Name'],
    'PrimaryTypeBn': type['NameBn'],
    'ClaimedBy': employeeId,
    ...personFields('ClaimedByName', memberOrNull(graph, employeeId)),
    'PersonCount': personCount,
    'IncurredFrom': AppDateUtils.toApiDateOnly(day),
    'ProspectId': prospect?.id,
    'ProspectName': prospect?.name,
    'VisitId': visitId,
    'Description': description,
    'StartLocation': from,
    'EndLocation': to,
    'LastReturnNote': note,
    'ApprovalStep': approvalStep,
    if (decided && stage != ExpenseStage.returned)
      ...personFields('ApprovedByName', approver),
    'Attachments': [
      for (final name in receipts) {'Name': name},
    ],
    'CreatedOn': jsonUtc(day.add(const Duration(hours: 19))),
  }..removeWhere((_, value) => value == null);
}

List<Map<String, dynamic>> expenseFixtures(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  final random = graph.random('expense');
  var id = 1;

  void add(int employeeId, int ago, ExpenseStage stage, {_Template? pick}) {
    final rowId = id++;
    final template = pick ?? _templates[random.nextInt(_templates.length)];
    final company = _companyFor(graph, employeeId, random);
    final amount = template.amount(random);
    final type = expenseTypeRow(template.typeId);
    final threshold = jsonDouble(type['ReceiptRequiredAbove']);
    final needsReceipt = threshold != null && amount > threshold;
    final visitId =
        template.typeId == travelTypeId && employeeId == SeedGraph.meId
        ? 1 + random.nextInt(6)
        : null;
    final visit = visitId == null ? null : expenseVisitRow(graph, visitId);
    rows.add(
      expenseRow(
        graph: graph,
        id: rowId,
        employeeId: employeeId,
        typeId: template.typeId,
        amount: amount,
        day: graph.daysAgo(ago),
        stage: stage,
        description: template.text.replaceAll('{company}', company.name),
        from: visit?['StartLocation'] as String? ?? template.from,
        to: visit?['EndLocation'] as String? ?? template.to,
        prospectId: visit?['ProspectId'] as int? ?? company.id,
        visitId: visitId,
        personCount: template.typeId == entertainmentTypeId
            ? 2 + random.nextInt(4)
            : 1,
        receipts: needsReceipt || random.nextBool()
            ? ['bill_${rowId.toString().padLeft(3, '0')}.jpg']
            : const [],
        note: switch (stage) {
          ExpenseStage.returned => 'Bill-er chhobi clear na, abar din',
          ExpenseStage.rejected => 'Personal travel — not a client visit',
          _ => null,
        },
      ),
    );
  }

  final me = SeedGraph.meId;
  for (var i = 0; i < 28; i++) {
    final ago = i * 2 + random.nextInt(2);
    final stage = switch (i) {
      0 || 1 || 2 => ExpenseStage.pending,
      5 => ExpenseStage.returned,
      9 || 17 => ExpenseStage.rejected,
      12 => ExpenseStage.withdrawn,
      _ when ago < 30 => ExpenseStage.approved,
      _ => ExpenseStage.paid,
    };
    add(me, ago, stage);
  }

  final others = graph.members.where((m) => m.id != me).toList();
  for (var m = 0; m < others.length; m++) {
    final count = 3 + random.nextInt(4);
    for (var i = 0; i < count; i++) {
      final ago = i * 6 + random.nextInt(5);
      final waits =
          i == 0 && m.isEven && approverOf(graph, others[m].id) != null;
      final stage = waits
          ? ExpenseStage.pending
          : (ago < 30 ? ExpenseStage.approved : ExpenseStage.paid);
      final big = waits && m < 8 ? _clientLunch : null;
      add(others[m].id, ago, stage, pick: big);
    }
  }
  final waiting = rows.where(
    (row) =>
        row['WorkflowStatus'] == 'pending' &&
        row['ClaimedBy'] != me &&
        (jsonDouble(row['ClaimedTotal']) ?? 0) > managerApprovalAbove,
  );
  for (final (i, row) in waiting.indexed) {
    if (i.isOdd) row['ApprovalStep'] = 2;
  }
  return rows;
}

SeedCompany _companyFor(SeedGraph graph, int employeeId, Random random) {
  final leads = graph.leadsOf(employeeId);
  if (leads.isEmpty) {
    return graph.companies[random.nextInt(graph.companies.length)];
  }
  return graph.company(leads[random.nextInt(leads.length)].companyId);
}

class _Template {
  const _Template(
    this.typeId,
    this.text,
    this.min,
    this.max, {
    this.from,
    this.to,
  });

  final int typeId;
  final String text;
  final int min;
  final int max;
  final String? from;
  final String? to;

  double amount(Random random) =>
      ((min + random.nextInt(max - min + 1)) ~/ 10 * 10).toDouble();
}

const _Template _clientLunch = _Template(
  entertainmentTypeId,
  'Lunch with {company} purchase team',
  2200,
  4500,
);

const List<_Template> _templates = [
  _Template(travelTypeId, 'CNG', 350, 900, from: 'Uttara', to: 'Banani'),
  _Template(
    travelTypeId,
    'রিকশা + বাস',
    120,
    300,
    from: 'Mirpur',
    to: 'Motijheel',
  ),
  _Template(travelTypeId, 'Uber', 450, 1200, from: 'Gulshan', to: 'Tejgaon'),
  _Template(
    travelTypeId,
    'Bus to {company} site',
    300,
    650,
    from: 'Tejgaon',
    to: 'Gazipur',
  ),
  _Template(
    travelTypeId,
    'Train to Chattogram, {company} meeting',
    1200,
    2600,
    from: 'Kamalapur',
    to: 'Chattogram',
  ),
  _Template(mealsTypeId, 'Lunch during {company} site survey', 250, 650),
  _Template(mealsTypeId, 'দুপুরের খাবার, Narayanganj visit', 200, 450),
  _clientLunch,
  _Template(entertainmentTypeId, 'Tea & snacks at {company} meeting', 300, 900),
  _Template(mobileTypeId, 'Mobile recharge — client calls', 300, 500),
  _Template(otherTypeId, 'Quotation printing for {company}', 150, 600),
  _Template(otherTypeId, 'Courier — sample panel to {company}', 400, 1500),
];
