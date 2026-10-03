import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

const _mentions = [
  'Has the Delta quotation gone out?',
  'ভাই, ওনার সাথে কাল মিটিং ফিক্স করেছি',
  'Customer wants 5kW hybrid, price ta ektu dekhben?',
  'সার্ভে রিপোর্ট আপলোড করেছি',
  'Can you join the site visit tomorrow?',
];

const _reminders = [
  'discuss quotation',
  'কোটেশন নিয়ে কথা',
  'payment follow-up',
  'demo er time fix korte hobe',
  'confirm site survey',
];

const _needs = [
  'solar panel',
  'সোলার প্যানেল',
  'rooftop 10kW',
  'IPS + battery',
  'solar pump for farm',
];

/// About six weeks of notifications for the signed-in user, newest first:
/// reminders, new leads, mentions, assignments, approvals, notices and
/// billing, each pointing at the screen it is about.
List<Map<String, dynamic>> notificationFixtures(SeedGraph graph) {
  final random = graph.random('notifications');
  final leads = graph.leads;
  if (leads.isEmpty) return const [];
  final colleagues = graph.members
      .where((m) => m.id != SeedGraph.meId)
      .toList();
  final lead = graph.members.firstWhere(
    (m) => m.role == WorkspaceRole.teamLead,
    orElse: () => graph.members.first,
  );
  final rows = <Map<String, dynamic>>[];
  var minutesAgo = 5;
  for (var i = 0; i < 46; i++) {
    final at = graph.anchor.subtract(Duration(minutes: minutesAgo));
    final subject = leads[(i * 7 + random.nextInt(5)) % leads.length];
    final company = graph.company(subject.companyId).name;
    final who = colleagues.isEmpty
        ? graph.me
        : colleagues[random.nextInt(colleagues.length)];
    rows.add({
      'Id': 46 - i,
      ..._template(
        i % 9,
        subject,
        company,
        graph.contact(subject.contactId),
        who,
        lead,
        random.nextInt(5),
      ),
      'CreatedAt': jsonUtc(at),
      'IsRead': i > 5 && (i > 14 || random.nextInt(3) > 0),
    });
    minutesAgo += i < 6 ? 35 + random.nextInt(60) : 180 + random.nextInt(900);
  }
  return rows;
}

Map<String, dynamic> _template(
  int slot,
  SeedLead subject,
  String company,
  SeedContact contact,
  SeedMember who,
  SeedMember teamLead,
  int roll,
) {
  final first = who.name.split(' ').first;
  final firstBn = who.nameBn.split(' ').first;
  return switch (slot) {
    0 || 5 => {
      'Kind': 'Reminder',
      'Title': 'Time to call · $company',
      'TitleBn': 'কল করার সময় · $company',
      'Body': _reminders[roll],
      'Route': Routes.leadFor(subject.id),
    },
    1 => {
      'Kind': 'NewLead',
      'Title': 'New lead arrived · ${subject.source}',
      'TitleBn': 'নতুন লিড এসেছে · ${subject.source}',
      'Body': '${contact.name} · ${_needs[roll]}',
      'Route': Routes.leadFor(subject.id),
    },
    2 => {
      'Kind': 'Mention',
      'Title': '$first mentioned you',
      'TitleBn': '$firstBn আপনাকে মেনশন করেছেন',
      'Body': '“${_mentions[roll]}”',
      'Route': '${Routes.chats}?leadId=${subject.id}',
    },
    3 => {
      'Kind': 'Assigned',
      'Title': 'Lead assigned · $company',
      'TitleBn': 'লিড বরাদ্দ · $company',
      'Body': 'From ${teamLead.name}',
      'Route': Routes.leadFor(subject.id),
    },
    4 => {
      'Kind': 'TaskDue',
      'Title': 'Follow-up due · $company',
      'TitleBn': 'ফলো-আপের সময় · $company',
      'Body': 'No contact for ${subject.lastTouchDaysAgo + 3} days',
      'Route': Routes.leadFor(subject.id),
    },
    6 => {
      'Kind': 'Approval',
      'Title': roll.isEven ? 'Leave approved' : 'Expense claim approved',
      'TitleBn': roll.isEven ? 'ছুটি অনুমোদিত' : 'খরচের দাবি অনুমোদিত',
      'Body': teamLead.name,
      'Route': roll.isEven ? Routes.leave : Routes.expenses,
    },
    7 => {
      'Kind': 'Notice',
      'Title': roll.isEven ? 'Notice: Eid holidays' : 'Notice: new price list',
      'TitleBn': roll.isEven ? 'নোটিশ: ঈদের ছুটি' : 'নোটিশ: নতুন মূল্য তালিকা',
      'Body': 'Office admin',
      'Route': Routes.notices,
    },
    _ => {
      'Kind': 'Billing',
      'Title': 'Plan renews in 7 days',
      'TitleBn': 'প্ল্যান নবায়ন ৭ দিন পরে',
      'Body': 'Team · ৳ 3,990',
      'Route': Routes.planUsage,
    },
  };
}
