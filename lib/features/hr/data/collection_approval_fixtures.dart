import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';

/// Collections reps logged in the field that wait for a lead's confirmation
/// before they count against the invoice.
List<Map<String, dynamic>> collectionApprovalFixtures(SeedGraph graph) {
  final random = graph.random('collection-approvals');
  final reps = graph.members.where((m) => m.id != SeedGraph.meId).toList();
  if (reps.isEmpty) return const [];
  return [
    for (var i = 0; i < 9; i++)
      _collectionRow(graph, random, i + 1, reps[random.nextInt(reps.length)]),
  ];
}

Map<String, dynamic> _collectionRow(
  SeedGraph graph,
  Random random,
  int id,
  SeedMember rep,
) {
  const methods = ['Cash', 'bKash', 'Cheque', 'Bank'];
  final leads = graph.leadsOf(rep.id);
  final company = leads.isEmpty
      ? graph.companies[random.nextInt(graph.companies.length)]
      : graph.company(leads[random.nextInt(leads.length)].companyId);
  final status = switch (id) {
    <= 3 => 'Pending',
    8 => 'Rejected',
    _ => 'Approved',
  };
  return {
    'Id': id,
    'EmployeeId': rep.id,
    ...personFields('EmployeeName', rep),
    'Amount': (15 + random.nextInt(470)) * 500,
    'Method': methods[random.nextInt(methods.length)],
    'CompanyId': company.id,
    'CompanyName': company.name,
    'HasSlip': random.nextInt(4) > 0,
    'CollectedAt': jsonUtc(graph.daysAgo(id * 3 - 3, hour: 12 + id % 5)),
    'Status': status,
    if (status == 'Rejected')
      'DecisionNote': 'Slip-er amount mile na, invoice abar check korun',
    if (status != 'Pending')
      ...personFields('DecidedByName', approverOf(graph, rep.id)),
  };
}
