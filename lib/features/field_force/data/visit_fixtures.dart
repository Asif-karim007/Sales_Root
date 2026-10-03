import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// The team's office at Gulshan-1, where the day's check-in is measured from.
const officeLat = 23.7808;
const officeLng = 90.4163;

/// A company's front door: its area's centre, nudged a few hundred metres so
/// two companies in one area don't share a pin.
(double, double) companySpot(SeedCompany company) {
  final area = company.area;
  final dLat = ((company.id * 37) % 13 - 6) * 0.0006;
  final dLng = ((company.id * 53) % 11 - 5) * 0.0007;
  return (area.lat + dLat, area.lng + dLng);
}

/// [metres] away from a point, towards [bearing] (radians).
(double, double) offsetBy(
  double lat,
  double lng,
  double metres,
  double bearing,
) {
  const metresPerDegree = 111320.0;
  final dLat = metres * cos(bearing) / metresPerDegree;
  final dLng = metres * sin(bearing) / (metresPerDegree * cos(lat * pi / 180));
  return (lat + dLat, lng + dLng);
}

/// Members who go out on visits: everyone but the owner of a team.
List<SeedMember> fieldMembers(SeedGraph graph) => [
  for (final member in graph.members)
    if (member.role != WorkspaceRole.owner || graph.members.length == 1) member,
];

Map<String, dynamic> memberJson(SeedMember member) => {
  'Id': member.id,
  'Name': member.name,
  'NameBn': member.nameBn,
};

Map<String, dynamic> areaJson(SeedArea area) => {
  'Name': area.name,
  'NameBn': area.nameBn,
};

/// Visits from three weeks back to three days ahead for every field member.
/// Today's list for the signed-in user mirrors the prototype: Karim Textiles
/// done in the morning, then Delta Power, Meghna Group and City Pharma.
List<Map<String, dynamic>> visitFixtures(SeedGraph graph) {
  if (graph.leads.isEmpty) return const [];
  final random = graph.random('visits');
  final rows = <Map<String, dynamic>>[];
  for (final member in fieldMembers(graph)) {
    final owned = graph.leadsOf(member.id);
    final leads = owned.isEmpty ? graph.leads : owned;
    for (var day = 21; day >= -3; day--) {
      final date = graph.daysAgo(day);
      if (date.weekday == DateTime.friday) continue;
      final isMeToday = member.id == SeedGraph.meId && day == 0;
      final count = 1 + random.nextInt(4);
      final todays = isMeToday
          ? _meToday(graph)
          : [
              for (var i = 0; i < count; i++)
                leads[random.nextInt(leads.length)],
            ];
      final slots = isMeToday
          ? _slots
          : (([..._slots]..shuffle(random)).take(count).toList()
              ..sort((a, b) => a.$1.compareTo(b.$1)));
      for (var i = 0; i < todays.length; i++) {
        rows.add(
          _visit(
            graph: graph,
            random: random,
            id: rows.length + 1,
            member: member,
            lead: todays[i],
            day: day,
            slot: slots[i],
            order: i + 1,
            purpose: isMeToday
                ? _meTodayPurposes[i]
                : _purposes[random.nextInt(_purposes.length)],
            keepPlanned: member.id == SeedGraph.meId && day == 0 && i > 0,
          ),
        );
      }
    }
  }
  return rows;
}

List<SeedLead> _meToday(SeedGraph graph) {
  final mine = graph.leadsOf(SeedGraph.meId);
  final pool = mine.isEmpty ? graph.leads : mine;
  SeedLead pick(int companyId) => pool.firstWhere(
    (l) => l.companyId == companyId,
    orElse: () => pool[companyId % pool.length],
  );
  return [pick(1), pick(2), pick(3), pick(10)];
}

Map<String, dynamic> _visit({
  required SeedGraph graph,
  required Random random,
  required int id,
  required SeedMember member,
  required SeedLead lead,
  required int day,
  required (int, int) slot,
  required int order,
  required String purpose,
  required bool keepPlanned,
}) {
  final company = graph.company(lead.companyId);
  final contact = graph.contact(lead.contactId);
  final (lat, lng) = companySpot(company);
  final planned = graph.daysAgo(day, hour: slot.$1, minute: slot.$2);
  final row = <String, dynamic>{
    'Id': id,
    'Employee': memberJson(member),
    'Lead': {'Id': lead.id, 'Name': lead.title},
    'Company': {'Id': company.id, 'Name': company.name},
    'ContactName': contact.name,
    'Area': areaJson(company.area),
    'Address': '${company.area.name} Road ${1 + company.id % 27}',
    'Latitude': lat,
    'Longitude': lng,
    'PlannedAt': jsonUtc(planned),
    'Purpose': purpose,
    'Order': order,
    'Status': 'Planned',
    'Photos': const <Map<String, dynamic>>[],
    'Notes': const <Map<String, dynamic>>[],
    'SampleProductIds': const <int>[],
    'CanEdit': member.id == SeedGraph.meId,
    'CanDelete': false,
  };
  if (day < 0 || keepPlanned) return row;

  final minutesSince = graph.anchor.difference(planned).inMinutes;
  if (day == 0 && minutesSince < 0) return row;
  if (day > 0 && random.nextInt(100) < 11) return {...row, 'Status': 'Missed'};

  final far = random.nextInt(100) < 7;
  final distance = far ? 400 + random.nextInt(1100) : 6 + random.nextInt(130);
  final (startLat, startLng) = offsetBy(
    lat,
    lng,
    distance.toDouble(),
    random.nextDouble() * 2 * pi,
  );
  final checkedIn = planned.add(Duration(minutes: random.nextInt(25) - 10));
  final duration = 20 + random.nextInt(50);
  final open = day == 0 && minutesSince < duration;
  row.addAll({
    'Status': open ? 'InProgress' : 'Done',
    'Start': {
      'Latitude': startLat,
      'Longitude': startLng,
      'Location': row['Address'],
      'Time': jsonUtc(checkedIn),
    },
    'CheckInDistance': distance,
    'IsFarCheckIn': far,
    if (far && random.nextBool())
      'FarReason': _farReasons[random.nextInt(_farReasons.length)],
    'SampleProductIds': [
      for (var i = 0; i < random.nextInt(3); i++) 1 + random.nextInt(42),
    ],
  });
  if (open) return row;

  final outcomeRoll = random.nextInt(100);
  final outcome = outcomeRoll < 10
      ? 'Ignored'
      : _outcomes[outcomeRoll % _outcomes.length];
  final notes = _outcomeNotes[outcome] ?? const <String>[];
  return row..addAll({
    'End': {
      'Latitude': startLat,
      'Longitude': startLng,
      'Location': row['Address'],
      'Time': jsonUtc(checkedIn.add(Duration(minutes: duration))),
    },
    'DurationMinutes': duration,
    'Outcome': outcome,
    if (notes.isNotEmpty) 'Note': notes[random.nextInt(notes.length)],
  });
}

const List<(int, int)> _slots = [(10, 0), (12, 0), (14, 30), (16, 30)];

const _meTodayPurposes = [
  'Show samples',
  'Discuss quotation',
  'Meet the MD about rooftop solar',
  'Collect ৳ 1.2 lakh',
];

const _purposes = [
  'Show samples',
  'Discuss quotation',
  'Collect payment',
  'Site survey for rooftop solar',
  'Hybrid inverter demo',
  'ব্যাটারি চেক করা',
  'Follow up on the proposal',
  'নতুন অর্ডার নিয়ে আলোচনা',
  'Installation progress check',
  'AMC renewal',
  'স্যাম্পল প্যানেল দেখানো',
];

const _outcomes = ['Interested', 'Order', 'ComeBackLater', 'NotInterested'];

const Map<String, List<String>> _outcomeNotes = {
  'Interested': [
    'Discussed quotation v2; decision on Monday.',
    'MD wants a 10 kW rooftop, will send roof photos.',
    'দাম নিয়ে কথা হলো, আগামী সপ্তাহে জানাবেন।',
    'Asked for a revised offer with the 10 kWh battery.',
  ],
  'Order': [
    'Confirmed 2 × hybrid inverter 5kW, advance next week.',
    'অর্ডার কনফার্ম, ডেলিভারি বৃহস্পতিবার।',
    'PO for 20 panels signed, installation from the 15th.',
  ],
  'ComeBackLater': [
    'Owner abroad, come back after the 15th.',
    'ম্যানেজার ছিলেন না, পরে আসতে বললেন।',
    'Budget meeting next month; visit again then.',
  ],
  'NotInterested': [
    'Already bought from another vendor.',
    'এ বছর বাজেট নেই।',
    'Prefers diesel generator for now.',
  ],
};

const _farReasons = [
  'Customer asked to meet at their warehouse',
  'গ্রাহক অন্য অফিসে ছিলেন',
  'Met at the factory site',
  'Road blocked, met near the main road',
];
