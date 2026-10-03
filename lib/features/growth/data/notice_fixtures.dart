import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/growth/models/notice.dart';

const growthNoticesTable = 'growth_notices';

/// Who a notice for [audience] reaches, leaving out its author.
List<SeedMember> noticeAudience(
  SeedGraph graph,
  NoticeAudience audience,
  int authorId,
) => [
  for (final member in graph.members)
    if (member.id != authorId &&
        switch (audience) {
          NoticeAudience.everyone => true,
          NoticeAudience.sales => member.role != WorkspaceRole.owner,
          NoticeAudience.field =>
            member.role == WorkspaceRole.member && member.id.isOdd,
          NoticeAudience.leads => member.role == WorkspaceRole.teamLead,
        })
      member,
];

/// A recipient row with the member's presence today.
Map<String, dynamic> noticeRecipient(
  SeedMember member, {
  DateTime? readAt,
  DateTime? acknowledgedAt,
}) => {
  'MemberId': member.id,
  'Name': member.name,
  'NameBn': member.nameBn,
  'ReadAt': jsonUtc(readAt),
  'AcknowledgedAt': jsonUtc(acknowledgedAt),
  'Presence': member.id != SeedGraph.meId && member.id % 6 == 0
      ? 'OnLeave'
      : member.id % 5 == 0
      ? 'Offline'
      : 'Active',
  'LastSeenDays': member.id % 5 == 0 ? 2 : member.id % 3,
};

List<Map<String, dynamic>> noticeFixtures(SeedGraph graph) {
  final owner = graph.members.firstWhere(
    (m) => m.role == WorkspaceRole.owner,
    orElse: () => graph.me,
  );
  final lead = graph.members.firstWhere(
    (m) => m.role == WorkspaceRole.teamLead,
    orElse: () => owner,
  );
  final best = graph.members[3 % graph.members.length];
  var id = 0;

  Map<String, dynamic> notice({
    required String title,
    required String body,
    required SeedMember author,
    required String role,
    required NoticeAudience audience,
    required int daysAgo,
    required double readShare,
    int hour = 9,
    bool ack = false,
    int pinDays = 0,
    bool meRead = true,
    List<Map<String, dynamic>> attachments = const [],
  }) {
    final noticeId = ++id;
    final posted = graph.daysAgo(daysAgo, hour: hour);
    final random = graph.random('notice$noticeId');
    return {
      'Id': noticeId,
      'Title': title,
      'Body': body,
      'AuthorId': author.id,
      'AuthorName': author.name,
      'AuthorNameBn': author.nameBn,
      'AuthorRole': role,
      'PostedAt': jsonUtc(posted),
      'Audience': audience.wire,
      'RequiresAck': ack,
      'Pinned': pinDays > 0,
      'PinUntil': pinDays > 0 ? jsonUtc(graph.daysAhead(pinDays)) : null,
      'Attachments': attachments,
      'Recipients': [
        for (final member in noticeAudience(graph, audience, author.id))
          if (member.id == SeedGraph.meId
              ? meRead
              : random.nextDouble() < readShare)
            noticeRecipient(
              member,
              readAt: posted.add(Duration(minutes: 5 + random.nextInt(600))),
              acknowledgedAt: ack && random.nextInt(5) > 0
                  ? posted.add(Duration(minutes: 30 + random.nextInt(900)))
                  : null,
            )
          else
            noticeRecipient(member),
      ],
    };
  }

  return [
    notice(
      title: 'ঈদের ছুটি ও অফিসের সময়',
      body:
          '৫–৯ অক্টোবর অফিস বন্ধ। জরুরি কালেকশন থাকলে টিম লিডকে জানান। ১০ অক্টোবর থেকে স্বাভাবিক।',
      author: owner,
      role: 'Admin',
      audience: NoticeAudience.everyone,
      daysAgo: 0,
      readShare: 0.78,
      ack: true,
      pinDays: 7,
      meRead: false,
    ),
    notice(
      title: 'September’s best: ${best.name}',
      body:
          '${best.name} closed ৳ 18.6 lakh in September, including the Meghna Group rooftop project. Congratulations! Lunch is on us on Sunday.',
      author: owner,
      role: 'Owner',
      audience: NoticeAudience.everyone,
      daysAgo: 1,
      hour: 18,
      readShare: 0.9,
    ),
    notice(
      title: 'New dealer price list',
      body:
          'Dealer prices for 550W panels and 5kW hybrid inverters change from 1 October. Use the attached list for every new quotation.',
      author: lead,
      role: 'TeamLead',
      audience: NoticeAudience.sales,
      daysAgo: 2,
      readShare: 0.85,
      attachments: [
        {'Name': 'Dealer_price_list_Oct_2026.pdf', 'SizeKb': 1340},
      ],
    ),
    notice(
      title: 'ভিজিটে ছবি বাধ্যতামূলক',
      body:
          'প্রতিটি সাইট ভিজিটে ছাদের অন্তত ২টি ছবি এবং মিটারের ছবি তুলে আপলোড করবেন। ছবি ছাড়া ভিজিট রিপোর্ট গ্রহণ করা হবে না।',
      author: owner,
      role: 'Owner',
      audience: NoticeAudience.field,
      daysAgo: 7,
      readShare: 0.95,
      ack: true,
    ),
    notice(
      title: 'Net metering paperwork now in-house',
      body:
          'From this month we handle DESCO and DPDC net metering applications for customers. Charge ৳ 15,000 per job; add it as a service line in the quotation.',
      author: owner,
      role: 'Owner',
      audience: NoticeAudience.sales,
      daysAgo: 10,
      readShare: 0.92,
    ),
    notice(
      title: 'অফিসে নতুন ডেমো কিট',
      body:
          '৩kW হোম কিটের একটি ডেমো সেট শোরুমে রাখা হয়েছে। কাস্টমার নিয়ে আসলে আগে রিসেপশনে জানাবেন।',
      author: lead,
      role: 'TeamLead',
      audience: NoticeAudience.sales,
      daysAgo: 14,
      readShare: 1,
      attachments: [
        {'Name': 'demo_kit.jpg', 'SizeKb': 820, 'Kind': 'Photo'},
      ],
    ),
    notice(
      title: 'Expense claims by the 5th',
      body:
          'Submit last month’s transport and food bills in the app by the 5th. Claims after that move to the next payroll.',
      author: owner,
      role: 'Admin',
      audience: NoticeAudience.everyone,
      daysAgo: 20,
      readShare: 1,
      ack: true,
    ),
    notice(
      title: 'Rooftop safety',
      body:
          'Always wear the harness on roofs above two floors and never work on wet panels. Report any unsafe site to your team lead before starting.',
      author: owner,
      role: 'Owner',
      audience: NoticeAudience.field,
      daysAgo: 30,
      readShare: 1,
      attachments: [
        {'Name': 'Rooftop_safety_checklist.pdf', 'SizeKb': 410},
      ],
    ),
    notice(
      title: 'Q4 targets',
      body:
          'Q4 team targets are in the shared sheet. Please review them with your members this week and send changes by Thursday.',
      author: owner,
      role: 'Owner',
      audience: NoticeAudience.leads,
      daysAgo: 45,
      readShare: 1,
    ),
  ];
}
