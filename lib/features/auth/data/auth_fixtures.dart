import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// The fake server's SMS code for every number.
const demoSmsCode = '123456';

/// Signs in as Karim Hossain, like any `SeedGraph` member's own number.
const demoPhone = '+8801711000000';

/// The email account on #12.
const demoEmail = 'karim@example.com';
const demoPassword = 'salesroot';

/// Accounts that already exist: every member of the seeded team, plus
/// [demoPhone] and [demoEmail] for Karim Hossain.
List<Map<String, dynamic>> authUserFixtures() {
  final graph = SeedGraph.build(
    workspaceId: 200,
    kind: WorkspaceKind.team,
    memberCount: 25,
    leadCount: 0,
  );
  final me = graph.me;
  return [
    for (final member in graph.members)
      {
        'Id': member.id,
        'UserId': member.id,
        'Name': member.name,
        'NameBn': member.nameBn,
        'Phone': member.phone,
        if (member.id == me.id) 'Email': demoEmail,
        if (member.id == me.id) 'Password': demoPassword,
      },
    {
      'Id': graph.members.length + 1,
      'UserId': me.id,
      'Name': me.name,
      'NameBn': me.nameBn,
      'Phone': demoPhone,
    },
  ];
}

List<Map<String, dynamic>> authInviteFixtures() => const [
  {
    'Id': 1,
    'Code': 'DS7Q2M',
    'WorkspaceId': 200,
    'WorkspaceName': 'Dhaka Sales',
    'InviterName': 'Mohammad Kamal',
    'InviterNameBn': 'মোহাম্মদ কামাল',
    'Role': 'Member',
    'MemberCount': 21,
    'LeadCount': 230,
    'Status': 'Pending',
  },
  {
    'Id': 2,
    'Code': 'MGS4K8',
    'WorkspaceId': 400,
    'WorkspaceName': 'Meghna Solar Dealers',
    'InviterName': 'Rafiqul Islam',
    'InviterNameBn': 'রফিকুল ইসলাম',
    'Role': 'Member',
    'MemberCount': 9,
    'LeadCount': 85,
    'Status': 'Pending',
  },
  {
    'Id': 3,
    'Code': 'CTG5TL',
    'WorkspaceId': 500,
    'WorkspaceName': 'Chattogram Projects',
    'InviterName': 'Tanvir Ahmed',
    'InviterNameBn': 'তানভীর আহমেদ',
    'Role': 'TeamLead',
    'MemberCount': 5,
    'LeadCount': 40,
    'Status': 'Pending',
  },
  {
    'Id': 4,
    'Code': 'OLD9X1',
    'WorkspaceId': 600,
    'WorkspaceName': 'Sylhet Rooftop Team',
    'InviterName': 'Shirin Sultana',
    'InviterNameBn': 'শিরিন সুলতানা',
    'Role': 'Member',
    'MemberCount': 4,
    'LeadCount': 12,
    'Status': 'Expired',
  },
];

List<Map<String, dynamic>> authReferralFixtures() => const [
  {
    'Id': 1,
    'Code': 'RH4K9P',
    'InviterName': 'Rahim Uddin',
    'InviterNameBn': 'রাহিম উদ্দিন',
    'CreditAmount': 50,
    'TrialDays': 15,
  },
  {
    'Id': 2,
    'Code': 'KH2026',
    'InviterName': 'Karim Hossain',
    'InviterNameBn': 'করিম হোসেন',
    'CreditAmount': 50,
    'TrialDays': 15,
  },
];
